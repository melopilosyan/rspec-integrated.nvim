local LL = vim.log.levels
local MAX_NOTIFY_TIMEOUT = 60 * 60 * 1000

local function notify(msg, log_level, title, predecessor)
  return vim.notify(msg, log_level, {
    title   = title,
    timeout = predecessor and 3000 or MAX_NOTIFY_TIMEOUT,
    replace = predecessor,
  })
end

---@param spec rspec.Spec
local function openning_notification_title(spec)
  if not spec.path then return "RSpec: Running the test suite..." end

  return spec.cmd[#spec.cmd]:find(":") and "RSpec: Running an example..."
      or "RSpec: Running a file..."
end

---@class rspec.Notif
---@field predecessor any nvim-notify plugin record
local Notif = {}

---@param spec rspec.Spec
function Notif:new(spec)
  self.__index = self

  return setmetatable({
    predecessor = notify(table.concat(spec.cmd, " "), LL.WARN, openning_notification_title(spec))
  }, self)
end

---@param msg string
function Notif:success(msg)
  notify(msg, LL.INFO, "RSpec: Succeeded", self.predecessor)
end

---@param msg string
---@param title? string
function Notif:failure(msg, title)
  notify(msg, LL.ERROR, title or "RSpec: Failed", self.predecessor)
end

return Notif
