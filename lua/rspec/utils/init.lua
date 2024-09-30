local Timer = require("rspec.utils.timer")
local Notif = require("rspec.utils.notif")

local M = {}

---@class rspec.ExecutionResultContext
---@field stdout string[]
---@field succeeded boolean
---@field notify_success fun(msg: string)
---@field notify_failure fun(msg: string|string[], title?: string)

local function split_lines(str)
  return vim.split(str, "\n", { trimempty = true })
end

--- Failure with the following output:
---
---   An error occurred while loading rails_helper.
---   Failure/Error: config.include Udefined, type: :view
---
---   NameError:
---     uninitialized constant Udefined
---   # ./spec/rails_helper.rb:57:in `block in <main>'
---   # ./spec/rails_helper.rb:46:in `<main>'
---   ...
---
local function failure_error_msg(stdout)
  local msg = {}
  for _, line in ipairs(split_lines(stdout)) do
    if not line:find("#") then table.insert(msg, line) else break end
  end
  return msg
end

---@param spec rspec.Spec
---@param on_exit fun(exec: rspec.ExecutionResultContext)
M.execute = function(spec, on_exit)
  local notif = Notif(spec)

  if not spec:executable_in_cwd() then
    return notif.failure("Can't find RSpec executable in CWD", "RSpec: Command not found")
  end

  local timer = Timer:new()

  ---@param obj vim.SystemCompleted
  vim.system(spec.cmd, { text = true }, vim.schedule_wrap(function(obj)
    timer:save_duration()

    if obj.code ~= 0 and #obj.stdout == 0 then
      return notif.failure(split_lines(obj.stderr), "RSpec: Command failed")
    elseif obj.stdout:find("Failure/Error:") then
      return notif.failure(failure_error_msg(obj.stdout), "RSpec: Command failed")
    end

    on_exit({
      stdout = split_lines(obj.stdout),
      succeeded = obj.code == 0,
      notify_failure = notif.failure,
      notify_success = function(msg)
        notif.success(timer:attach_duration(msg))
      end,
    })
  end))
end

return M
