-- Cmds for managing
-- :Lazy   	-> Opens lazy.nvim plugin manager
-- :Manson 	-> Opens Manson external tool manager
-- :checkhealth -> Run healtcheck on nvim config

-- use package manager 'lazy.nvim'
require("config.lazy")

-- load custom settings
require("custom.enforce-unix-eol").setup()
require("custom.line-numbers").setup()
require("custom.key-mappings").setup()
require("custom.tabs").setup()

-- No swap file please !
vim.opt.swapfile = false
