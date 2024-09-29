local Timer = require("rspec.utils.timer")
local Notif = require("rspec.utils.notif")

local M = {}

--- Defines the RSpec execution command for the project.
---
--- In the following order of availability:
---   `bin/rspec` - Typically found in Rails apps.
---   `bundle exec rspec` - Ruby projects managed via bundler.
---   `rspec` - The default RSpec executable.
---@return string[]
local function command()
  if vim.fn.executable("bin/rspec") == 1 then
    return { "bin/rspec" }
  elseif vim.fn.filereadable("Gemfile") == 1 then
    return { "bundle", "exec", "rspec" }
  else
    return { "rspec" }
  end
end

---@class rspec.Spec
--- Execution specification
---@field cmd string[] RSpec command for the project
---@field path? string Test file path

---@return rspec.Spec
M.spec = function(command_arguments)
  local cmd = command()

  for _, arg in ipairs(command_arguments) do table.insert(cmd, arg) end

  return { cmd = cmd }
end

---@class rspec.ExecutionResultContext
---@field stdout string[]
---@field succeeded boolean
---@field notify_success fun(msg: string)
---@field notify_failure fun(msg: string|string[], title?: string)

---@param spec rspec.Spec
---@param on_exit fun(exec: rspec.ExecutionResultContext)
M.execute = function(spec, on_exit)
  local notif = Notif(spec)
  local timer = Timer:new()

  vim.system(spec.cmd, { text = true }, function(obj)
    timer:save_duration()

    on_exit({
      stdout = vim.split(obj.stdout, "\n", { trimempty = true }),
      succeeded = obj.code == 0,
      notify_failure = notif.failure,
      notify_success = function(msg)
        notif.success(timer:attach_duration(msg))
      end,
    })
  end)
end

return M
