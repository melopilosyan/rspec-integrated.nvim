local Timer = require("rspec.timer")
local Notif = require("rspec.notif")

---@class rspec.ExecutionResultContext
---@field stdout string[]
---@field succeeded boolean
---@field notify_success fun(msg: string)
---@field notify_failure rspec.FailureFun

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
return function(spec)
  local notif = Notif(spec:cmd_to_string(), spec:summary())

  if spec:not_runnable(notif.failure) then return end

  local timer = Timer():start()

  ---@param obj vim.SystemCompleted
  vim.system(spec.cmd, { text = true }, vim.schedule_wrap(function(obj)
    timer:stop()

    if obj.code ~= 0 and #obj.stdout == 0 then
      return notif.failure(split_lines(obj.stderr), "RSpec: Command failed")
    elseif obj.stdout:find("^[^{]+Failure/Error:") then
      return notif.failure(failure_error_msg(obj.stdout), "RSpec: Command failed")
    end

    spec.on_exit({
      stdout = split_lines(obj.stdout),
      succeeded = obj.code == 0,
      notify_failure = notif.failure,
      notify_success = function(msg)
        notif.success(timer:append_runtime(msg))
      end,
    })
  end))
end
