-- Project-local keymaps
-- Copy this file to the root of your project and adjust to your needs.
-- Neovim will prompt you to trust it on first load (once per file change).
-- Use <leader>1 through <leader>9 for project-specific shortcuts.

-- Example: Rust / Cargo project
vim.keymap.set("n", "<leader>1", function()
	vim.cmd("w")
	vim.cmd("!cargo check")
end, { desc = "cargo check" })

vim.keymap.set("n", "<leader>2", function()
	vim.cmd("w")
	vim.cmd("!cargo run")
end, { desc = "cargo run" })

vim.keymap.set("n", "<leader>3", function()
	vim.cmd("w")
	vim.cmd("!cargo test")
end, { desc = "cargo test" })

vim.keymap.set("n", "<leader>4", function()
	print("Moin Moin")
end, { desc = "Moin Moin" })

-- Example: C project
vim.keymap.set("n", "<leader>5", function()
	vim.cmd("w")
	vim.cmd("!gcc main.c -o main -g")
end, { desc = "compile main.c" })

vim.keymap.set("n", "<leader>6", function()
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

-- Add more shortcuts here (<leader>7 .. <leader>9)
