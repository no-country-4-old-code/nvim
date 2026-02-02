local M = {}

function M.setup()
	-- rust (cargo)
	vim.keymap.set("n", "<leader>cc", function()
		vim.cmd("w")
		vim.cmd("!cargo check")
	end, { noremap = true, silent = true })

	vim.keymap.set("n", "<leader>cr", function()
		vim.cmd("w")
		vim.cmd("!cargo run")
	end, { noremap = true, silent = true })

	-- telescope keymaps
	local telescope = require("telescope.builtin")
	vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "telescope find files" })
	vim.keymap.set(
		"n",
		"<leader>fg",
		":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
		{ desc = "telescope live grep" }
	)
	vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "telescope buffers" })
	vim.keymap.set("n", "<leader>fj", telescope.jumplist, { desc = "telescope list jumps" })
	vim.keymap.set("n", "<leader>gc", telescope.git_commits, { desc = "telescope shows git commits" })
	vim.keymap.set("n", "<leader>gf", telescope.git_bcommits, { desc = "telescope shows git commits (buffer)" })
	vim.keymap.set("n", "<leader>gb", telescope.git_branches, { desc = "telescope shows git branches" })
	vim.keymap.set("n", "<leader>gs", telescope.git_status, { desc = "telescope shows git status" })

	-- ! telescope internal key-mappings are specified in plugin-file

	-- telescope keymaps for my custom extensions
	local extension = require("plugins.extensions.telescope")
	vim.keymap.set("n", "<leader>gd", extension.diff.to_commit, { desc = "telescope shows git status" })

	-- nvim-tree keymaps
	local tree = require("nvim-tree.api")
	vim.keymap.set("n", "<leader>ft", function()
		tree.tree.toggle({ find_file = true, focus = true })
	end, { desc = "nvim-tree: toggle tree view" })
	-- ! nvim-tree internal key-mappings are specified in plugin-file
end

return M
