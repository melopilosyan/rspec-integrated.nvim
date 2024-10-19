return {
  run = function()
    local path = vim.fn.expand("%:.")

    if not path:find("_spec.rb$") then
      vim.notify("Run it on a *_spec.rb file", vim.log.levels.WARN, { title = "RSpec: Not a spec file" })
      return
    end

    local cmd = string.format("bin/rspec %s:%s", path, vim.api.nvim_win_get_cursor(0)[1])

    local buf = vim.api.nvim_create_buf(false, true)

    -- Open top-level horizontal split below
    local win_id = vim.api.nvim_open_win(buf, true, { split = "below", win = -1 })
    vim.api.nvim_set_option_value("number", false, { win = win_id })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win_id })

    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")

    -- Automatically close the window after finishing the debugging session
    vim.api.nvim_create_autocmd("TermClose", { buffer = buf, command = "bd" })
    -- Hide the terminal buffer from buffers list
    vim.api.nvim_set_option_value("buflisted", false, { scope = "local" })
    -- Map Esc key in terminal to switch to nomal mode
    vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-N>", { noremap = true })
  end
}
