local notify_failure = require("rspec.notif")()

---@class rspec.DebugSpec : rspec.Spec
local spec = require("rspec.spec")()

function spec:on_cmd_changed()
  self.cmd_str = self:cmd_to_string()
end

function spec:build_final_command()
  self.full_cmd = string.format("%s %s:%s", self.cmd_str, self.path, self.current_linenr)
end

spec.runner = function()
  ---@diagnostic disable-next-line: param-type-mismatch
  if spec:not_runnable(notify_failure) then return end

  local buf = vim.api.nvim_create_buf(false, true)

  -- Open top-level horizontal split below without number line
  local win_id = vim.api.nvim_open_win(buf, true, { split = "below", win = -1 })
  vim.api.nvim_set_option_value("number", false, { win = win_id })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win_id })

  vim.cmd("terminal " .. spec.full_cmd)
  vim.cmd("startinsert")

  -- Automatically close the window if the process exits successfully
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    callback = function()
      if vim.v.event.status == 0 then vim.api.nvim_buf_delete(buf, {}) end
    end
  })
  -- Hide the terminal buffer from buffers list
  vim.api.nvim_set_option_value("buflisted", false, { scope = "local" })
  -- Map Esc key in terminal to switch to nomal mode
  vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-N>", { noremap = true })
end

return spec
