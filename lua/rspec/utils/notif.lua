local nvim_notify_loaded, _ = pcall(require, "notify")

---@param spec rspec.Spec
local function openning_notification_title(spec)
  if not spec.path then return "RSpec: Running the test suite..." end

  return spec.cmd[#spec.cmd]:find(":") and "RSpec: Running an example..."
      or "RSpec: Running a file..."
end

---@param spec rspec.Spec
return function(spec)
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

  notify(table.concat(spec.cmd, " "), vim.log.levels.WARN, {
    title = openning_notification_title(spec),
    timeout = false,
  })

  if nvim_notify_loaded then simulate_progress_animation() end

  ---@class rspec.Notif
  ---@field success fun(msg: string)
  ---@field failure fun(msg: string, title?: string)
  return {
    success = function(msg)
      complete(msg, "INFO", "RSpec: Succeeded")
    end,
    failure = function(msg, title)
      complete(msg, "ERROR", title or "RSpec: Failed")
    end,
  }
end
