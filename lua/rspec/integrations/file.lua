-- Local globals
local DROP_ERROR_CLASSES  = "RSpec::Expectations"
local FIRST_CHARACTER     = "%S"
local FAILURE_STATUS      = "failed"
local LINENR_REGEX        = ":(%d+)"
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

-- Local references of functions
local fmt = string.format
local get_lines = vim.api.nvim_buf_get_lines

---@class rspec.FileSpec : rspec.Spec
local spec = require("rspec.spec")()

function spec:summary()
  local example = self.run_current_example or self.path and self.cmd[self.filepath_position]:find(":")
  return example and "RSpec: Running an example..." or "RSpec: Running a file..."
end

function spec:on_cmd_changed()
  self:apply_cmd_options({ "--format=json" })
  self.filepath_position = #self.cmd + 1
  self.cwd_length = #self.cwd + 1
end

function spec:build_final_command()
  local path_argument = self.run_current_example and
      fmt("%s:%s", self.path, self.current_linenr) or self.path

  self.bufnr = vim.api.nvim_get_current_buf()
  self.cmd[self.filepath_position] = path_argument
end

local not_json_output

---@param stdout string[]
---@return boolean, string
local function decode_json(stdout)
  local json = ""
  not_json_output = "\n"

  for _, line in ipairs(stdout) do
    if line:find('"errors_outside_of_examples_count":') then
      json = line:match("({.*})")
    else
      not_json_output = fmt("%s\n%s", not_json_output, line)
    end
  end

  return pcall(vim.json.decode, json)
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

---@class rspec.FileIntegration
---@field result table
---@field failures table
---@field notif_title? string
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
    self.notif_title = "RSpec: Error"

  elseif summary.example_count == 0 then
    self.notif_title = self.result.messages[1]

  elseif summary.failure_count > 0 then
    self:populate_failures()
  end
end

---@param exec rspec.ExecutionResultContext
function Integration:notify_completion(exec)
  local res = self.result

  if #self.failures == 0 then
    exec.notify_success(fmt("%s in %.3fs", res.summary_line, res.summary.duration))
  else
    exec.notify_failure(res.summary_line, self.notif_title)
  end
end

---@param exec rspec.ExecutionResultContext
function Integration:perform(result, exec)
  local integration = setmetatable({
    result = result,
    failures = {},
  }, self)

  integration:process_test_result()
  integration:notify_completion(exec)

  vim.diagnostic.set(DIAG.namespace, spec.bufnr, integration.failures, DIAG.config)
end

---@param exec rspec.ExecutionResultContext
spec.on_exit = function(exec)
  local ok, result = decode_json(exec.stdout)

  if ok then
    Integration:perform(result, exec)
  else
    exec.notify_failure(result, "RSpec: Error")
  end
end

return spec
