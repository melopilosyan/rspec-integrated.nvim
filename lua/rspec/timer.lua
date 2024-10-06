return function()
  ---@class rspec.Timer
  local timer = { start_time = 0, duration = 0 }

  function timer:start()
    self.start_time = vim.fn.reltime()
    return self
  end

  function timer:stop()
    self.duration = self:elapsed_seconds()
  end

  function timer:elapsed_seconds()
    local diff = vim.fn.reltime(self.start_time)
    return vim.fn.reltimefloat(diff)
  end

  function timer:append_runtime(str)
    return string.format("%s (runtime: %.3fs)", str, self.duration)
  end

  return timer
end
