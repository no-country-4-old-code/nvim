-- Project-local keymaps
-- Copy this file to the root of your project and adjust to your needs.
-- Neovim will prompt you to trust it on first load (once per file change).

-- Load project-local LSP configuration
local ok, lspconfig = pcall(require, "lspconfig")
if not ok then
	return
end

--  Configure LSP server for C/C++
lspconfig.clangd.setup({
	cmd = {
		"clangd", -- compiler
		"--compile-commands-dir=build", -- build folder to search for compile_commands.json
		"--clang-tidy", -- inline warnings
		"--background-index", -- needed for go-to-definition etc.
		"--completion-style=detailed", -- needed for completion-style
	},
})

-- Use <leader>1 through <leader>9 for project-specific shortcuts.
-- Example: C project
vim.keymap.set("n", "<leader>1", function()
	vim.cmd("w")
	vim.cmd("! g++ main.cpp -o main")
	vim.cmd("! ./main")
	vim.cmd("! rm main")
end, { desc = "run main" })

vim.keymap.set("n", "<leader>2", function()
	vim.cmd("w")
	local result = vim.fn.system("gcc main.c -o main -g")
	if vim.v.shell_error ~= 0 then
		vim.notify("Compile failed:\n" .. result, vim.log.levels.ERROR)
		return
	end
	require("dap").run({
		name = "Launch (gdb)",
		type = "cppdbg",
		request = "launch",
		program = vim.fn.getcwd() .. "/main",
		cwd = "${workspaceFolder}",
		stopAtEntry = true,
		MIMode = "gdb",
	})
end, { desc = "compile & debug main.c" })

vim.keymap.set("n", "<leader>3", function()
	vim.cmd("w")
	vim.cmd("!cargo test")
end, { desc = "cargo test" })

vim.keymap.set("n", "<leader>4", function()
	print("Moin Moin")
end, { desc = "Moin Moin" })
