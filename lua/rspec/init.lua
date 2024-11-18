local M = {}

---@class rspec.Options
--- Options controlling the behaviour of the plugin
---@field current_example? boolean Whether to run the test example the cursor is in or the entire spec file.
---@field repeat_last_run? boolean Whether to execute the last command regardless of the current file and/or cursor position.
---@field suite? boolean Whether to run the entire test suite or the current spec file.
---@field debug? boolean Whether to run the nearest example in the terminal, allowing interactive debugging.

local previous_integration = nil

---@param options rspec.Options
local function integration_name(options)
  local name

  if options.repeat_last_run and previous_integration then
    name = previous_integration
  elseif options.debug then
    name = "debug"
  elseif options.suite then
    name = "suite"
  else
    name = "file"
  end

  previous_integration = name
  return name
end

--- Plugin's entry point.
---
--- Runs RSpec
---   1) against the current spec file
---     registering failures as Neovim diagnostic entries
---     a) against the current test example
---        if called with the `current_example = true` option
---     b) repeats last run
---        if triggered not in a spec file buffer or
---        if called with the `repeat_last_run = true` option
---   2) against the test suite
---     displaying failures as a quickfix list
---   3) against the nearest example in the terminal
---     allowing interactive debugging
---
--- Usage:
--- ```lua
---   require("rspec").run() -- (1)
---   require("rspec").run({ suite = true }) -- (2)
---   require("rspec").run({ debug = true }) -- (3)
---   require("rspec").run({ repeat_last_run = true }) -- (1.b)
---   require("rspec").run({ current_example = true }) -- (1.a)
--- ```
---@param options? rspec.Options
M.run = function(options)
  options = options or {}

  vim.cmd("silent! wa")

  require("rspec.integrations." .. integration_name(options)):run(options)
end

return M
