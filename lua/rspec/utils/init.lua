local Timer = require("rspec.utils.timer")

local M = {}
local MAX_NOTIFY_TIMEOUT = 60 * 60 * 1000

---@alias rspec.Cmd string[] RSpec command for the project

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
--- Data passed down to the `vim.system` on exit callback
---@field succeeded boolean Execution completed with return value 0
---@field stdout string[] RSpec standard output as a list of strings
---@field timer rspec.Timer

---@param cmd rspec.Cmd
---@param on_exit fun(syscom: rspec.SystemCompleted)
M.system = function(cmd, on_exit)
  local timer = Timer:new()

  vim.system(cmd, { text = true }, function(obj)
    timer:save_duration()

    on_exit({
      stdout = vim.split(obj.stdout, "\n", { trimempty = true }),
      succeeded = obj.code == 0,
      timer = timer,
    })
  end)
end

M.notify = function(msg, log_level, title, replacement)
  return vim.notify(msg, log_level, {
    title   = title,
    timeout = replacement and 3000 or MAX_NOTIFY_TIMEOUT,
    replace = replacement,
  })
end

return M
