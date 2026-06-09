return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = {
		use_icons = false,
		keymaps = {
			view = {
				-- merging changes
				{
					"n",
					"<leader>gp",
					function()
						vim.cmd("diffput")
					end,
					{ desc = "Git-Diff : Push hunk to other panel" },
				},
				{ "v", "<leader>gp", ":diffput<CR>", { desc = "Git-Diff : Push selected lines to other panel" } },
				{
					"n",
					"<leader>gl",
					function()
						vim.cmd("diffget")
					end,
					{ desc = "Git-Diff : Get hunk from other panel" },
				},

				-- git staging
				{ "v", "<leader>gl", ":diffget<CR>", { desc = "Git-Diff : Get selected lines from other panel" } },
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
				{ "n", "zo", "zo", { desc = "Open fold" } },
				{ "n", "zc", "zc", { desc = "Close fold" } },
			},
			file_panel = {},
		},
		hooks = {
			diff_buf_win_enter = function(bufnr, winid, ctx)
				vim.opt_local.foldmethod = "diff"
				vim.opt_local.foldlevel = 0
				vim.cmd("normal! zM")
			end,
		},
	},
}
