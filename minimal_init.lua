local fn  = vim.fn
local cwd = fn.getcwd()

vim.opt.rtp:prepend(cwd)
vim.opt.rtp:prepend(cwd .. "/misc/plenary")

-- Fail fast if plenary isn’t present
local ok = pcall(require, "plenary")
if not ok then
  error("Plenary not found on runtimepath. Run `make deps`.")
end

vim.opt.swapfile = false

