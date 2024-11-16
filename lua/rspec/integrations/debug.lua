local function notify_failure(msg, title)
  vim.notify(msg, vim.log.levels.ERROR, { title = title, icon = " " })
end

---@class rspec.DebugSpec : rspec.Spec
local spec = require("rspec.spec")()

function spec:on_cmd_changed()
  self.cmd_str = self:cmd_to_string()
end

function spec:resolve_run_context()
  self:set_current_spec_file_path()
  local current_linenr = vim.api.nvim_win_get_cursor(0)[1]
  self.full_cmd = string.format("%s %s:%s", self.cmd_str, self.current_path, current_linenr)
end

function spec:integration_not_runnable(notify)
  if not self.in_spec_file then
    notify("Run it on a *_spec.rb file", "RSpec: Not a spec file")
    return true
  end
end

spec.runner = function()
  if spec:not_runnable(notify_failure) then return end

  local buf = vim.api.nvim_create_buf(false, true)

  -- Open top-level horizontal split below without number line
  local win_id = vim.api.nvim_open_win(buf, true, { split = "below", win = -1 })
  vim.api.nvim_set_option_value("number", false, { win = win_id })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win_id })

  vim.cmd("terminal " .. spec.full_cmd)
  vim.cmd("startinsert")

  -- Automatically close the window after finishing the debugging session
  vim.api.nvim_create_autocmd("TermClose", { buffer = buf, command = "bd" })
  -- Hide the terminal buffer from buffers list
  vim.api.nvim_set_option_value("buflisted", false, { scope = "local" })
  -- Map Esc key in terminal to switch to nomal mode
  vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-N>", { noremap = true })
end

return spec
