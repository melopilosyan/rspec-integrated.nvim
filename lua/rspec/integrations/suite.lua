---@class rspec.SuiteSpec : rspec.Spec
local spec = require("rspec.spec")()

function spec:summary()
  return "RSpec: Running the test suite..."
end

function spec:on_cmd_changed()
  self:apply_cmd_options({ "--format=failures", "--exclude-pattern=spec/system/*" })
end

-- Opt out of these features
function spec:resolve_run_context() end
function spec:integration_not_runnable(_) return false end

---@param failures string[] List of strings in "file/path:line-number:failed test description" format
local function to_qflist(failures)
  local qflist, re, path, lnum, desc
  qflist = {}
  re = "(.*):(%d+):(.*)"

  for _, line in ipairs(failures) do
    path, lnum, desc = line:match(re)

    if path then
      table.insert(qflist, { filename = path, lnum = lnum, text = desc })
    end
  end

  return qflist
end

---@param exec rspec.ExecutionResultContext
spec.on_exit = function(exec)
  if exec.succeeded then
    exec.notify_success("All tests passed")
  else
    vim.fn.setqflist(to_qflist(exec.stdout), "r")
    vim.cmd("copen")

    exec.notify_failure("See the quickfix list")
  end
end

return spec
