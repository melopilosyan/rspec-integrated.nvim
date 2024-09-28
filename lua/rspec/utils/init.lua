local Timer = require("rspec.utils.timer")
local Notif = require("rspec.utils.notif")

local M = {}

---@alias rspec.Cmd string[] RSpec command for the project

---@class rspec.Spec
--- Execution specification
---@field cmd rspec.Cmd
---@field path? string Test file path

--- Defines the RSpec execution command for the project.
---
--- In the following order of availability:
---   `bin/rspec` - Typically found in Rails apps.
---   `bundle exec rspec` - Ruby projects managed via bundler.
---   `rspec` - The default RSpec executable.
---@return rspec.Cmd
M.cmd = function()
  if vim.fn.executable("bin/rspec") == 1 then
    return { "bin/rspec" }
  elseif vim.fn.filereadable("Gemfile") == 1 then
    return { "bundle", "exec", "rspec" }
  else
    return { "rspec" }
  end
end

---@class rspec.SystemCompleted
--- Data passed down to the `utils.execute` on exit callback
---@field succeeded boolean Execution completed with return value 0
---@field stdout string[] RSpec standard output as a list of strings
---@field timer rspec.Timer
---@field notif rspec.Notif

---@param spec rspec.Spec
---@param on_exit fun(syscom: rspec.SystemCompleted)
M.execute = function(spec, on_exit)
  local notif = Notif(spec)
  local timer = Timer:new()

  vim.system(spec.cmd, { text = true }, function(obj)
    timer:save_duration()

    on_exit({
      stdout = vim.split(obj.stdout, "\n", { trimempty = true }),
      succeeded = obj.code == 0,
      timer = timer,
      notif = notif,
    })
  end)
end

return M
