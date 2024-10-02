local nvim_notify_loaded, _ = pcall(require, "notify")

--- Defines a notification round for a specific run: start - progress - end.
---
--- Displays a notification with starting message and title, initiates the progress
--- animation if applicable, and returns a Notif table with `success` and `failure`
--- methods, ending the round.
---
---@param starting_msg string
---@param starting_title string
return function(starting_msg, starting_title)
  local icons = {
    ERROR = " ",
    INFO = " ",
  }

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

  local function complete(msg, level, title)
    frame = nil

    notify(msg, vim.log.levels[level], {
      icon = icons[level],
      title = title,
      timeout = 3000,
      hide_from_history = false,
    })
  end

  notify(starting_msg, vim.log.levels.WARN, {
    title = starting_title,
    timeout = false,
  })

  if nvim_notify_loaded then simulate_progress_animation() end

  ---@class rspec.Notif
  ---@field success fun(msg: string)
  ---@field failure fun(msg: string|string[], title?: string)
  return {
    success = function(msg)
      complete(msg, "INFO", "RSpec: Succeeded")
    end,

    failure = function(msg, title)
      if not nvim_notify_loaded and type(msg) == "table" then
        msg = table.concat(msg, "\n")
      end
      complete(msg, "ERROR", title or "RSpec: Failed")
    end,
  }
end
