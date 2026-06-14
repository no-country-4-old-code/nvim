-- Cmds for managing
-- :Lazy   	-> Opens lazy.nvim plugin manager
-- :Mason 	-> Opens Mason external tool manager
-- :checkhealth -> Run healthcheck on nvim config

-- use package manager 'lazy.nvim'
require("config.lazy")

-- load custom settings
require("custom.enforce-unix-eol").setup()
require("custom.line-numbers").setup()
require("custom.key-mappings").setup()
require("custom.tabs").setup()
require("custom.dep-graph").setup()

-- No swap file please !
vim.opt.swapfile = false

-- Load .nvim.lua from project root if present (nvim will prompt to trust on first load)
vim.opt.exrc = true
