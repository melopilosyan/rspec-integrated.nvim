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
  ---
  --- Integrations must define these methods
  ---@field summary fun():string Job introduction (initial notification title)
  ---@field on_exit fun(exec: rspec.ExecutionResultContext)
  ---@field on_cmd_changed fun()
  local spec = {}

  function spec:resolve_cmd()
    local cwd = vim.fn.getcwd() .. "/"
    if self.cwd == cwd then return end

    self.cwd = cwd
    self.cmd = command()

    self:on_cmd_changed()
  end

  function spec:resolve_run_context()
    -- Prepare for execution, e.g. build the full command to run.
  end

  function spec:executable_in_cwd()
    return #self.cmd > 0
  end

  --- Each integration decides when and why it cannot run and displays a notification.
  ---@param notify_failure fun(msg: string|string[], title?: string)
  ---@diagnostic disable-next-line: unused-local
  function spec:not_runnable(notify_failure)
    return false
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
    self.suite = opts.suite
  end

  ---@param opts rspec.Options
  function spec:run(opts)
    self:assign_options(opts)
    self:resolve_cmd()
    self:resolve_run_context()

    require("rspec.runner")(self)
  end

  return spec
end
