local nvim_notify_loaded, _ = pcall(require, "notify")

local LL = vim.log.levels
local Icons = {
  ERROR = " ",
  INFO = " ",
}

local icon_frames = { "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾" }
icon_frames.count = #icon_frames

---@param notif rspec.Notif
function icon_frames:next_for(notif)
  notif.frame = (notif.frame + 1) % self.count
  return self[notif.frame]
end

---@param spec rspec.Spec
local function openning_notification_title(spec)
  if not spec.path then return "RSpec: Running the test suite..." end

  return spec.cmd[#spec.cmd]:find(":") and "RSpec: Running an example..."
      or "RSpec: Running a file..."
end

---@class rspec.Notif
---@field package frame number
---@field private predecessor any nvim-notify record
local Notif = {}

---@param spec rspec.Spec
function Notif:new(spec)
  self.__index = self

  local instance = setmetatable({
    frame = 1,
    predecessor = vim.notify(table.concat(spec.cmd, " "), LL.WARN, {
      title = openning_notification_title(spec),
      icon = icon_frames[1],
      timeout = false,
    })
  }, self)

  if nvim_notify_loaded then instance:show_loading() end

  return instance
end

---@param msg string
function Notif:success(msg)
  self:complete(msg, "INFO", "RSpec: Succeeded")
end

---@param msg string
---@param title? string
function Notif:failure(msg, title)
  self:complete(msg, "ERROR", title or "RSpec: Failed")
end

---@private
---@param msg string
---@param level string
---@param title string
function Notif:complete(msg, level, title)
  self.frame = nil

  self.predecessor = vim.notify(msg, LL[level], {
    icon = Icons[level],
    title = title,
    timeout = 3000,
    replace = self.predecessor,
    hide_from_history = false,
  })
end

---@private
function Notif:show_loading()
  if not self.frame then return end

  self.predecessor = vim.notify(nil, nil, {
    icon = icon_frames:next_for(self),
    replace = self.predecessor,
    hide_from_history = true,
  })

  vim.defer_fn(function() self:show_loading() end, 150)
end

return Notif
