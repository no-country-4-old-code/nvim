local M = {}

function M.setup()
	-- modules
	local telescope = require("telescope.builtin")

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

	-- debug
	vim.keymap.set("n", "<leader>db", function()
		require("dap").toggle_breakpoint()
	end, { desc = "Debug : Toggle breakpoint" })
	vim.keymap.set("n", "<leader>dc", function()
		require("dap").continue()
	end, { desc = "Debug : Continue / start" })
	vim.keymap.set("n", "<leader>dn", function()
		require("dap").step_over()
	end, { desc = "Debug : Step over" })
	vim.keymap.set("n", "<leader>di", function()
		require("dap").step_into()
	end, { desc = "Debug : Step into" })
	vim.keymap.set("n", "<leader>do", function()
		require("dap").step_out()
	end, { desc = "Debug : Step out" })
	vim.keymap.set("n", "<leader>dx", function()
		require("dap").terminate()
	end, { desc = "Debug : Terminate" })
	vim.keymap.set("n", "<leader>dp", function()
		require("dap").pause()
	end, { desc = "Debug : Pause" })
	vim.keymap.set("n", "<leader>dr", function()
		require("dap").restart()
	end, { desc = "Debug : Restart" })
	vim.keymap.set("n", "<leader>du", function()
		require("dapui").toggle()
	end, { desc = "Debug : Toggle UI" })
	vim.keymap.set("n", "<leader>de", function()
		require("dapui").eval()
	end, { desc = "Debug : Evaluate expression" })
	vim.keymap.set(
		"n",
		"<leader>dinfo",
		function() end,
		{ desc = "Debug : In side windows use e(dit), t(oggle), o(pen), c(ode), d(elete) " }
	)
	vim.keymap.set("n", "<leader>dw", function()
		require("dapui").elements.watches.add(vim.fn.expand("<cword>"))
	end, { desc = "Debug : Add word under cursor to watch" })

	-- window picker
	vim.keymap.set("n", "<leader>w", function()
		local win = require("window-picker").pick_window()
		if win then
			vim.api.nvim_set_current_win(win)
		end
	end, { desc = "Pick window to jump to" })

	-- ! keymaps used inside modules like 'telescope' or 'nvim-tree' are define in the related plugin-files
end

return M
