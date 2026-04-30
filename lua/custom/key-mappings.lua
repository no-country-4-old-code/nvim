local M = {}

function M.setup()
	-- modules
	local telescope = require("telescope.builtin")
	local ext_telescope = require("plugins.extensions.telescope")

	-- helper
	local function show_keymaps()
		telescope.keymaps({
			filter = function(km)
				return km.desc ~= nil and km.desc ~= ""
			end,
		})
	end

	local function find_files()
		telescope.find_files({
			sorter = require("telescope.sorters").get_substr_matcher(),
		})
	end

	local function open_file_tree()
		local tree = require("nvim-tree.api")
		tree.tree.toggle({ find_file = true, focus = true })
	end

	-- general
	vim.keymap.set("n", "<leader>h", show_keymaps, { desc = "Show keymaps" })

	-- navigation
	vim.keymap.set("n", "<leader>ft", open_file_tree, { desc = "Open file tree (navigation)" })
	vim.keymap.set("n", "<leader>fj", telescope.jumplist, { desc = "Browse jump history (navigation)" })
	vim.keymap.set("n", "<leader>ff", find_files, { desc = "Search by file name (navigation)" })
	vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Search in file contents (navigation)" })
	vim.keymap.set("n", "<leader>fr", telescope.registers, { desc = "Browse registers (navigation)" })
	vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Browse open buffers (navigation)" })

	-- code navigation via (lsp)
	vim.keymap.set("n", "<leader>cl", telescope.diagnostics, { desc = "Browse diagnostics (linter) (code)" })
	vim.keymap.set("n", "<leader>cd", telescope.lsp_definitions, { desc = "Go to definition (code)" })
	vim.keymap.set("n", "<leader>cu", telescope.lsp_references, { desc = "Find usages / references (code)" })
	vim.keymap.set("n", "<leader>ci", telescope.lsp_incoming_calls, { desc = "Callstack up (who calls this) (code)" })
	vim.keymap.set(
		"n",
		"<leader>co",
		telescope.lsp_outgoing_calls,
		{ desc = "Callstack down (what this calls) (code)" }
	)

	-- git
	vim.keymap.set("n", "<leader>gc", telescope.git_commits, { desc = "Browse git commits" })
	vim.keymap.set("n", "<leader>gf", telescope.git_bcommits, { desc = "Browse git commits for this file" })
	vim.keymap.set("n", "<leader>gb", telescope.git_branches, { desc = "Browse git branches" })
	vim.keymap.set("n", "<leader>gs", telescope.git_status, { desc = "Browse git status" })
	vim.keymap.set("n", "<leader>gd", ext_telescope.diff.to_commit, { desc = "Compare current git commit to others" })

	-- ! keymaps used inside modules like 'telescope' or 'nvim-tree' are define in the related plugin-files
end

return M
