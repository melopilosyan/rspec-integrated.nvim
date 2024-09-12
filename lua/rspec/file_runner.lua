local utils = require("rspec.utils")

-- Local globals
local COVERAGE_LINE_REGEX = "Coverage report generated.*$"
local DROP_ERROR_CLASSES  = "RSpec::Expectations"
local SPEC_FILE_PATTERN   = "_spec.rb$"
local FIRST_CHARACTER     = "%S"
local FAILURE_STATUS      = "failed"
local LINENR_REGEX        = ":(%d+)"
local LL                  = vim.log.levels
local DIAG                = { -- Diagnostics info
  source    = "RSpec",
  severity  = vim.diagnostic.severity.ERROR,
  namespace = vim.api.nvim_create_namespace("rspec.integrated"),
  config    = {
    virtual_text = {
      format = function(_) return "Failure" end,
    },
  },
}
local NT                  = { -- Notify titles
  running   = "RSpec: Running...",
  succeeded = "RSpec: Succeeded",
  failed    = "RSpec: Failed",
  error     = "RSpec: Error",
}

-- Local references of functions
local fmt = string.format
local get_lines = vim.api.nvim_buf_get_lines

-- Measures execution time.
local timer = {}

function timer:reltime()
  return vim.fn.reltimefloat(vim.fn.reltime())
end

function timer:start()
  self.start_time = self:reltime()
end

function timer:duration()
  return self:reltime() - self.start_time
end

-- Holds the run command and related information.
local spec = {}

function spec:resolve_cmd()
  local cmd = utils.cmd()

  table.insert(cmd, "--format=j")

  self.filepath_spot_in_cmd = #cmd + 1
  self.cmd = cmd
end
spec:resolve_cmd()

---@param options rspec.Options
function spec:assign_params(options)
  self.run_current_example = options.only_current_example
  self.repeat_last_run = options.repeat_last_run
end

function spec:cmd_argument()
  if not self.run_current_example then return self.path end

  return fmt("%s:%s", self.path, self.current_linenr)
end

function spec:should_update_path()
  return not self.path and self.in_spec_file or
      self.path and self.in_spec_file and self.current_path ~= self.path
end

function spec:resolve_cmd_argument()
  if self.repeat_last_run then return end

  self.current_path = vim.fn.expand("%:.")
  self.in_spec_file = self.current_path:find(SPEC_FILE_PATTERN)

  if self:should_update_path() then
    self.path = self.current_path
    self.bufnr = vim.api.nvim_get_current_buf()
    self.cwd = vim.fn.getcwd() .. "/"
    self.cwd_length = #self.cwd + 1
  end

  if not self.in_spec_file then return end

  self.current_linenr = vim.api.nvim_win_get_cursor(0)[1]
  self.cmd[self.filepath_spot_in_cmd] = self:cmd_argument()
end

local not_json_output
local function rspec_json_from(stdout)
  local rspec_out = ""
  not_json_output = "\n"

  for _, line in ipairs(stdout) do
    if line:find('"errors_outside_of_examples_count":') then
      rspec_out = line
    else
      not_json_output = fmt("%s\n%s", not_json_output, line)
    end
  end

  return rspec_out:gsub(COVERAGE_LINE_REGEX, "")
end

local function decode_json(stdout)
  local json = rspec_json_from(stdout)

  local ok, result = pcall(vim.json.decode, json)
  if not ok then print(result, json); return end

  return result
end

local function linenr_col(backtrace_line)
  local linenr = tonumber(backtrace_line:match(spec.path .. LINENR_REGEX)) or 1
  local line = get_lines(spec.bufnr, linenr - 1, linenr, false)[1]
  local col = line:find(FIRST_CHARACTER)

  return linenr, col
end

local function full_message(msg, klass, backtrace)
  local sep = msg:sub(1, 1) == "\n" and "\n" or "\n\n"
  local msg_class = klass:find(DROP_ERROR_CLASSES) and "" or klass .. "\n"

  return fmt("%s%s%s%s%s\n\n%s", sep, msg_class, msg, sep, backtrace, not_json_output)
end

local function linenr_col_message(exception)
  local linenr, col, includes_cwd
  local app_backtrace = "Backtrace:"

  local backtrace = exception.backtrace
  if backtrace == vim.NIL then backtrace = {} end

  for _, record in ipairs(backtrace) do
    includes_cwd = record:find(spec.cwd)
    -- Take only those records that come from the application files
    if includes_cwd or record:match("^%./") then
      if not linenr and record:find(spec.path) then
        linenr, col = linenr_col(record)
      end

      if includes_cwd then
        record = record:sub(spec.cwd_length, -1)
      end
      app_backtrace = fmt("%s\n%s", app_backtrace, record)
    end
  end

  return linenr or spec.current_linenr,
         col or 1,
         full_message(exception.message, exception.class, app_backtrace)
end

-- Namespace of methods sharing common data. Or just a pseudo-class.
local Integration = {}
Integration.__index = Integration

function Integration:insert_failure(linenr, col, message)
  return table.insert(self.failures, {
    lnum     = linenr - 1,
    col      = col - 1,
    message  = message,
    source   = DIAG.source,
    severity = DIAG.severity,
  })
end

function Integration:populate_failures()
  local linenrs = {}

  for _, example in ipairs(self.result.examples) do
    if example.status == FAILURE_STATUS then
      local linenr, col, message = linenr_col_message(example.exception)

      -- Do not add multiple errors on the same line
      if not vim.tbl_contains(linenrs, linenr) then
        self:insert_failure(linenr, col, message)
        table.insert(linenrs, linenr)
      end
    end
  end
end

function Integration:process_test_result()
  local summary = self.result.summary

  if summary.errors_outside_of_examples_count > 0 then
    local message = self.result.messages[1]
    local linenr, col = linenr_col(message)

    self:insert_failure(linenr, col, message)
    self.notif_title = NT.error

  elseif summary.example_count == 0 then
    self.notif_title = self.result.messages[1]

  elseif summary.failure_count > 0 then
    self:populate_failures()
    self.notif_title = NT.failed
  end
end

function Integration:notify_completion(replacement_notif)
  local message = self.result.summary_line
  local succeeded = vim.tbl_isempty(self.failures)
  local log_level = succeeded and LL.INFO or LL.ERROR

  if succeeded then
    message = fmt("%s   (duration: %.4f)", message, timer:duration())
  end

  utils.notify(message, log_level, self.notif_title, replacement_notif)
end

function Integration:perform(result, replacement_notif)
  local integration = setmetatable({
    result = result,
    failures = {},
    notif_title = NT.succeeded,
  }, self)

  vim.schedule(function()
    integration:process_test_result()
    integration:notify_completion(replacement_notif)

    vim.diagnostic.set(DIAG.namespace, spec.bufnr, integration.failures, DIAG.config)
  end)
end

---@param options rspec.Options
return function(options)
  spec:assign_params(options)
  spec:resolve_cmd_argument()

  if not spec.path then return end

  local notif = utils.notify(table.concat(spec.cmd, " "), LL.WARN, NT.running)

  timer:start()

  utils.system(spec.cmd, function(stdout)
    local result = decode_json(stdout)

    if not result then
      return utils.notify("Failed to parse test output", LL.ERROR, NT.error, notif)
    end

    Integration:perform(result, notif)
  end)
end
