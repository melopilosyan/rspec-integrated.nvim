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
  ---@field on_cmd_changed fun() NOTE: Should be defined per runner
  local spec = {}

  function spec:resolve_cmd()
    local cwd = vim.fn.getcwd() .. "/"
    if self.cwd == cwd then return end

    self.cwd = cwd
    self.cmd = command()

    if self:executable_in_cwd() then self:on_cmd_changed() end
  end

  function spec:executable_in_cwd()
    return #self.cmd > 0
  end

  ---@param opts string[] Command line options: "--format=f"
  function spec:apply_cmd_options(opts)
    for _, arg in ipairs(opts) do table.insert(self.cmd, arg) end
  end

  return spec
end
