---@class rspec.Timer
--- Measures execution time
---@field start_time float
---@field duration float
local Timer = {}

function Timer.reltime()
  return vim.fn.reltimefloat(vim.fn.reltime())
end

function Timer:new()
  self.__index = self

  return setmetatable({
    start_time = self.reltime(),
  }, self)
end

function Timer:save_duration()
  self.duration = self:elapsed_seconds()
end

function Timer:attach_duration(str)
  return string.format("%s   (duration: %.4f sec)", str, self.duration)
end

function Timer:elapsed_seconds()
  return self.reltime() - self.start_time
end

return Timer
