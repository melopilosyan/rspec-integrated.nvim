local utils = require("rspec.utils")

local function resolve_cmd()
  local cmd = utils.cmd()

  table.insert(cmd, "--format=f")
  table.insert(cmd, "--exclude-pattern=spec/system/*")

  return cmd
end

---@class rspec.SuiteSpec : rspec.Spec
local spec = { cmd = resolve_cmd() }

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
  utils.execute(spec, function(syscom)
    if syscom.succeeded then
      syscom.notif:success(syscom.timer:attach_duration("All tests passed"))
    else
      show_as_quickfix_list(syscom.stdout)

      syscom.notif:failure("See the quickfix list")
    end
  end)
end
