local utils = require("rspec.utils")

---@class rspec.SuiteSpec : rspec.Spec
local spec = utils.spec({ "--format=f", "--exclude-pattern=spec/system/*" })

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

return function(_)
  utils.execute(spec, function(exec)
    if exec.succeeded then
      exec.notify_success("All tests passed")
    else
      vim.fn.setqflist(to_qflist(exec.stdout), "r")
      vim.cmd("copen")

      exec.notify_failure("See the quickfix list")
    end
  end)
end
