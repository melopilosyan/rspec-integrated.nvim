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

---@param failures string[] Failed test entries
local function show_as_quickfix_list(failures)
  if #failures == 0 then return end

  vim.schedule(function()
    vim.fn.setqflist(to_qflist(failures), "r")
    vim.cmd("copen")
  end)
end

return function(_)
  utils.execute(spec, function(exec)
    if exec.succeeded then
      exec.notify_success("All tests passed")
    else
      show_as_quickfix_list(exec.stdout)

      exec.notify_failure("See the quickfix list")
    end
  end)
end
