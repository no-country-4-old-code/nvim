local M = {}

function M.setup()
	-- modules
	local telescope = require("telescope.builtin")
	local git = require("plugins.extensions.telescope.git")
	local dap = require("dap")
	local dapui = require("dapui")

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

	local function pick_window_to_jump()
		local win = require("window-picker").pick_window()
		if win then
			vim.api.nvim_set_current_win(win)
		end
	end

	local lsp_border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }
	local function lsp_hover()
		vim.lsp.buf.hover({ border = lsp_border })
	end

	local function lsp_signature()
		vim.lsp.buf.signature_help({ border = lsp_border })
	end

	-- general
	vim.keymap.set("n", "<leader>h", show_keymaps, { desc = "Show keymaps" })

	-- navigation
	vim.keymap.set("n", "<leader>ft", open_file_tree, { desc = "Navigation : Open file tree" })
	vim.keymap.set("n", "<leader>fj", telescope.jumplist, { desc = "Navigation : Browse jump history" })
	vim.keymap.set("n", "<leader>ff", find_files, { desc = "Navigation : Search by file name" })
	vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Navigation : Search in file contents" })
	vim.keymap.set("n", "<leader>fr", telescope.registers, { desc = "Navigation : Browse copy & paste registers" })
	vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Navigation : Browse open buffers" })
	vim.keymap.set("n", "<leader>w", pick_window_to_jump, { desc = "Navigation : Pick window to jump to" })
	vim.keymap.set("n", "<C-o>", "<C-o>", { desc = "Navigation : Jump back to previous position" })
	vim.keymap.set("n", "<C-i>", "<C-i>", { desc = "Navigation : Jump forwad again" })
	vim.keymap.set({ "n", "o", "x" }, ",", "^", { desc = "Navigation : Set cursor to start of line" })
	vim.keymap.set({ "n", "o", "x" }, ".", "$", { desc = "Navigation : Set cursor to end of line" })

	-- code navigation via (lsp)
	vim.keymap.set("n", "<leader>cl", telescope.diagnostics, { desc = "LSP : Browse diagnostics (linter)" })
	vim.keymap.set("n", "<leader>cd", telescope.lsp_definitions, { desc = "LSP : Go to definition" })
	vim.keymap.set("n", "<leader>cu", telescope.lsp_references, { desc = "LSP : Find usages / references" })
	vim.keymap.set("n", "<leader>ci", telescope.lsp_incoming_calls, { desc = "LSP : Callstack up (who calls this)" })
	vim.keymap.set("n", "<leader>co", telescope.lsp_outgoing_calls, { desc = "LSP : Callstack down (what this calls)" })
	vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "LSP : Rename symbol" })
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP : Code actions" })
	vim.keymap.set("n", "<leader>cm", vim.lsp.buf.implementation, { desc = "LSP : Jump to implementation" })
	vim.keymap.set("n", "<leader>ck", lsp_hover, { desc = "LSP : Hover docs of var" })
	vim.keymap.set("i", "<leader>ck", lsp_signature, { desc = "LSP : Show Fn-Signature help" })

	-- tabs
	vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Tabs : New empty tab (tabs)" })
	vim.keymap.set("n", "<leader>ts", "<cmd>tab split<CR>", { desc = "Tabs : Open current file in new tab (tabs)" })
	vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Tabs : Close current tab (tabs)" })

	-- git
	vim.keymap.set("n", "<leader>gq", telescope.git_status, { desc = "Git : Open git status (quick overview)" })
	vim.keymap.set("n", "<leader>gs", "<cmd>DiffviewOpen<CR>", { desc = "Git : Open git status (working tree diff)" })
	vim.keymap.set("n", "<leader>gc", git.git_commits, { desc = "Git : Browse commits" })
	vim.keymap.set("n", "<leader>gb", git.git_branches, { desc = "Git : Browse branches" })

	--  git history
	vim.keymap.set("n", "<leader>hr", "<cmd>DiffviewFileHistory<CR>", { desc = "Git-History: View repo history" })
	vim.keymap.set("n", "<leader>hf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git-History: View file history " })

	vim.keymap.set("n", "<leader>hd", git.history_diff_range, { desc = "Git-History : View diff between 2 commits" })

	-- debug
	vim.keymap.set("n", "<leader>db", function()
		dap.toggle_breakpoint()
	end, { desc = "Debug : Toggle breakpoint" })
	vim.keymap.set("n", "<leader>dc", function()
		dap.continue()
	end, { desc = "Debug : Continue / start" })
	vim.keymap.set("n", "<leader>dn", function()
		dap.step_over()
	end, { desc = "Debug : Step over" })
	vim.keymap.set("n", "<leader>di", function()
		dap.step_into()
	end, { desc = "Debug : Step into" })
	vim.keymap.set("n", "<leader>do", function()
		dap.step_out()
	end, { desc = "Debug : Step out" })
	vim.keymap.set("n", "<leader>dx", function()
		dap.terminate()
	end, { desc = "Debug : Terminate" })
	vim.keymap.set("n", "<leader>dp", function()
		dap.pause()
	end, { desc = "Debug : Pause" })
	vim.keymap.set("n", "<leader>dr", function()
		dap.restart()
	end, { desc = "Debug : Restart" })
	vim.keymap.set("n", "<leader>du", function()
		dapui.toggle()
	end, { desc = "Debug : Toggle UI" })
	vim.keymap.set("n", "<leader>de", function()
		dapui.eval()
	end, { desc = "Debug : Evaluate expression" })
	vim.keymap.set(
		"n",
		"<leader>dinfo",
		function() end,
		{ desc = "Debug : In side windows use e(dit), t(oggle), o(pen), c(ode), d(elete) " }
	)
	vim.keymap.set("n", "<leader>dw", function()
		dapui.elements.watches.add(vim.fn.expand("<cword>"))
	end, { desc = "Debug : Add word under cursor to watch" })
end

-- keymaps for gitsigns (buffer-local, set on attach)
function M.gitsigns_on_attach(bufnr)
	-- a really speed up during working on files
	local gs = require("gitsigns")
	vim.keymap.set("n", "f", gs.next_hunk, { buffer = bufnr, desc = "Git : Jump to next hunk" })
	vim.keymap.set("n", "t", gs.prev_hunk, { buffer = bufnr, desc = "Git : Jump to previous hunk" })
end

-- keymaps for diffview only
M.diffview_view_keymaps = {
	-- hunk navigation
	{ "n", "f", "]c", { desc = "Git-Diff : Jump to next hunk" } },
	{ "n", "t", "[c", { desc = "Git-Diff : Jump to previous hunk" } },

	-- merging changes
	{ "n", "<leader>gp", "<cmd>diffput<CR>", { desc = "Git-Diff : Push hunk to other panel" } },
	{ "v", "<leader>gp", ":diffput<CR>", { desc = "Git-Diff : Push selected lines to other panel" } },
	{ "n", "<leader>gl", "<cmd>diffget<CR>", { desc = "Git-Diff : Get hunk from other panel" } },
	{ "v", "<leader>gl", ":diffget<CR>", { desc = "Git-Diff : Get selected lines from other panel" } },

	-- git staging (gitsigns)
	{
		"n",
		"<leader>ga",
		function()
			require("gitsigns").stage_hunk()
		end,
		{ desc = "Git-Changes : Stage hunk (git)" },
	},
	{
		"v",
		"<leader>ga",
		function()
			local l1 = vim.fn.line("'<")
			local l2 = vim.fn.line("'>")
			require("gitsigns").stage_hunk({ l1, l2 })
		end,
		{ desc = "Git-Changes : Stage selected lines (git)" },
	},
	{
		"n",
		"<leader>gu",
		function()
			require("gitsigns").undo_stage_hunk()
		end,
		{ desc = "Git-Changes : Unstage hunk (git)" },
	},

	-- folds
	{ "n", "zo", "zo", { desc = "Open fold" } },
	{ "n", "zc", "zc", { desc = "Close fold" } },
}

-- keymaps for diffview -> fileview
M.diffview_file_history_panel_keymaps = {
	-- override default <CR> (select_entry: opens diff but stays in panel) so it
	-- opens the diff AND moves focus into the diff window
	{
		"n",
		"<cr>",
		function()
			require("diffview.actions").focus_entry()
		end,
		{ desc = "Git-History : Open diff and focus the diff window" },
	},
}

return M
