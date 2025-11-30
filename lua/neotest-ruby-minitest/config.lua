local M = {}

---@class config.Config
---@field command string Command to run the tests. Should be a string.
---@field env table<string, string>|nil Environment variables to set when running tests.

M.defaults = {
  -- Default command to run the tests
  -- You can override this with a custom command
  -- For example:
  -- command = "bundle exec ruby -Itest"
  command = "ruby -Itest",
  -- Environment variables to set when running tests
  -- These are merged with any env vars passed via neotest run args
  -- For example:
  -- env = { RAILS_ENV = "test", VERBOSE = "1" }
  env = {},
}

function M.resolve(opts)
  return vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
