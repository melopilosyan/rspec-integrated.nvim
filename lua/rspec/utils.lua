local M = {}
local MAX_NOTIFY_TIMEOUT = 60 * 60 * 1000

--- Defines the RSpec execution command for the project.
---
--- In the following order of availability:
---   `bin/rspec` - Typically found in Rails apps.
---   `bundle exec rspec` - Ruby projects managed via bundler.
---   `rspec` - The default RSpec executable.
---@return string[]
M.cmd = function()
  if vim.fn.executable("bin/rspec") == 1 then
    return { "bin/rspec" }
  elseif vim.fn.filereadable("Gemfile") == 1 then
    return { "bundle", "exec", "rspec" }
  else
    return { "rspec" }
  end
end

M.notify = function(msg, log_level, title, replacement)
  return vim.notify(msg, log_level, {
    title   = title,
    timeout = replacement and 3000 or MAX_NOTIFY_TIMEOUT,
    replace = replacement,
  })
end

return M
