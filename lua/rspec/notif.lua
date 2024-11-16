local nvim_notify_loaded, _ = pcall(require, "notify")
local ICONS = {
  ERROR = " ",
  INFO = " ",
}

local function end_params(msg, level, title)
  if not nvim_notify_loaded and type(msg) == "table" then
    msg = table.concat(msg, "\n")
  end

  return msg, vim.log.levels[level], {
    icon = ICONS[level],
    title = title,
    timeout = 3000,
    hide_from_history = false,
  }
end

---@alias rspec.FailureFun fun(msg: string|string[], title?: string)

--- Defines a notification round for a specific run: start - progress - end.
---
--- Displays a notification with starting message and title, initiates the progress
--- animation if applicable, and returns a Notif table with `success` and `failure`
--- methods, ending the round.
---
--- Or, if called without parameters, returns a one-off `notify_failure` function.
---
---@param starting_msg? string
---@param starting_title? string
---@return rspec.FailureFun | rspec.Notif
return function(starting_msg, starting_title)
  if not starting_msg then
    return function(msg, title)
      vim.notify(end_params(msg, "ERROR", title))
    end
  end

  ---@type number|nil Progress frame index or nil to stop
  local frame = 1
  local progress_frames = { "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾" }
  local notification = nil

  local function notify(msg, ll, opts)
    opts.replace = notification
    opts.icon = opts.icon or progress_frames[frame]

    notification = vim.notify(msg, ll, opts)
  end

  local function simulate_progress_animation()
    if frame == nil then return end

    frame = (frame + 1) % #progress_frames
    notify(nil, nil, { hide_from_history = true })

    vim.defer_fn(simulate_progress_animation, 150)
  end

  notify(starting_msg, vim.log.levels.WARN, {
    title = starting_title,
    timeout = false,
  })

  if nvim_notify_loaded then simulate_progress_animation() end

  ---@class rspec.Notif
  ---@field success fun(msg: string)
  ---@field failure rspec.FailureFun
  return {
    success = function(msg)
      frame = nil
      notify(end_params(msg, "INFO", "RSpec: Test passed"))
    end,
    failure = function(msg, title)
      frame = nil
      notify(end_params(msg, "ERROR", title or "RSpec: Test Failed"))
    end,
  }
end
