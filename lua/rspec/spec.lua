--- Selects the RSpec command/executable for the project.
---
--- In the following order of availability:
---   `bin/rspec`
---   `bundle exec rspec`
---   `rspec`
---@return string[]
local function command()
  if vim.fn.executable("bin/rspec") == 1 then
    return { "bin/rspec" }
  elseif vim.fn.filereadable("Gemfile") == 1 then
    return { "bundle", "exec", "rspec" }
  elseif vim.fn.executable("rspec") == 1 then
    return { "rspec" }
  else
    return {}
  end
end

return function()
  ---@class rspec.Spec
  --- Execution specification
  ---@field cmd string[] RSpec command for the project
  ---@field cwd string Current working directory
  ---@field path? string Test file path
  ---@field executable_in_cwd boolean Whether an RSpec executable is found to run from the CWD
  ---
  --- Methods defined per integration, if applicable
  ---@field summary fun():string Job introduction (initial notification title)
  ---@field on_exit fun(exec: rspec.ExecutionResultContext)
  ---@field on_cmd_changed fun()
  ---@field build_final_command fun()
  local spec = {}

  function spec:resolve_cmd()
    local cwd = vim.fn.getcwd() .. "/"
    if self.cwd == cwd and self.executable_in_cwd then return end

    self.cwd = cwd
    self.cmd = command()
    self.executable_in_cwd = #self.cmd > 0

    self.path = nil
    self.current_path = nil
    self:on_cmd_changed()
  end

  function spec:resolve_run_context()
    if self.repeat_last_run then return end

    self.current_path = vim.fn.expand("%:.")
    self.in_spec_file = self.current_path:find("_spec.rb$")

    if not self.in_spec_file then return end

    self.path = self.current_path
    self.current_linenr = vim.api.nvim_win_get_cursor(0)[1]
    self:build_final_command()
  end

  function spec:cmd_to_string()
    return table.concat(self.cmd, " ")
  end

  ---@param notify_failure rspec.FailureFun
  function spec:not_runnable(notify_failure)
    if not spec.executable_in_cwd then
      notify_failure("Can't find RSpec executable in CWD", "RSpec: Command not found")
      return true
    end

    return self:integration_not_runnable(notify_failure)
  end

  --- Each integration decides when and why it cannot run and displays a notification.
  --- Default setting for file-based integrations.
  ---@param notify_failure rspec.FailureFun
  function spec:integration_not_runnable(notify_failure)
    if not self.current_path then
      notify_failure("Has not yet run in the current working directory", "RSpec: Unable to replay last run")
      return true
    elseif not self.path then
      notify_failure("Run it on a *_spec.rb file", "RSpec: Not a spec file")
      return true
    end
  end

  ---@param opts string[] Command line options: "--format=f"
  function spec:apply_cmd_options(opts)
    for _, arg in ipairs(opts) do table.insert(self.cmd, arg) end
  end

  ---@param opts rspec.Options
  function spec:assign_options(opts)
    ---@diagnostic disable-next-line: undefined-field
    self.run_current_example = opts.current_example or opts.only_current_example
    self.repeat_last_run = opts.repeat_last_run
  end

  --- Set the default runner, allowing integrations to change it.
  spec.runner = require("rspec.runner")

  ---@param opts rspec.Options
  function spec:run(opts)
    self:assign_options(opts)
    self:resolve_cmd()
    self:resolve_run_context()

    self.runner(self)
  end

  return spec
end
