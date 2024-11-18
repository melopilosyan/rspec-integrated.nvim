-- Maintain backward compatibility
-- with the `require("rspec.integrated")` directive and the very first
-- `run_spec_file` entry point.

local M = require("rspec")

M.run_spec_file = M.run

return M
