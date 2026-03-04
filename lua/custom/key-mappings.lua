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

	-- helper
	local function grep_by_extensions()
		local input = vim.fn.input("Extensions (e.g. c cs json): ")
		if input == "" then
			return
		end
		local globs = {}
		for ext in input:gmatch("%S+") do
			table.insert(globs, "*." .. ext)
		end
		telescope.live_grep({ glob_pattern = globs })
	end

	local function show_keymaps()
		telescope.keymaps({
			filter = function(km)
				return km.desc ~= nil and km.desc ~= ""
			end,
		})
	end

	-- code navigation (lsp)
	vim.keymap.set("n", "<leader>cl", telescope.diagnostics, { desc = "Browse diagnostics (linting)" })
	vim.keymap.set("n", "<leader>cd", telescope.lsp_definitions, { desc = "Go to definition" })
	vim.keymap.set("n", "<leader>cu", telescope.lsp_references, { desc = "Find usages / references" })
	vim.keymap.set("n", "<leader>ci", telescope.lsp_incoming_calls, { desc = "Callstack up (who calls this)" })
	vim.keymap.set("n", "<leader>co", telescope.lsp_outgoing_calls, { desc = "Callstack down (what this calls)" })
	vim.keymap.set("n", "<leader>cj", telescope.jumplist, { desc = "Browse jump history" })
	vim.keymap.set("n", "<leader>h", show_keymaps, { desc = "Show keymaps" })
	vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Search by file name" })
	vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Search in file contents" })
	vim.keymap.set("n", "<leader>fe", grep_by_extensions, { desc = "Search in file contents (filter by extension)" })
	vim.keymap.set("n", "<leader>fr", telescope.registers, { desc = "Browse registers" })
	vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Browse open buffers" })
	vim.keymap.set("n", "<leader>gc", telescope.git_commits, { desc = "Browse git commits" })
	vim.keymap.set("n", "<leader>gf", telescope.git_bcommits, { desc = "Browse git commits for this file" })
	vim.keymap.set("n", "<leader>gb", telescope.git_branches, { desc = "Browse git branches" })
	vim.keymap.set("n", "<leader>gs", telescope.git_status, { desc = "Browse git status" })

	-- ! telescope internal key-mappings are specified in plugin-file

	-- telescope keymaps for my custom extensions
	local extension = require("plugins.extensions.telescope")
	vim.keymap.set("n", "<leader>gd", extension.diff.to_commit, { desc = "Diff file against commit" })

	-- nvim-tree keymaps
	local tree = require("nvim-tree.api")
	vim.keymap.set("n", "<leader>ft", function()
		tree.tree.toggle({ find_file = true, focus = true })
	end, { desc = "Toggle file tree" })
	-- ! nvim-tree internal key-mappings are specified in plugin-file
end

return M
