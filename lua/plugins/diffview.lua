return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = {
		use_icons = false,
		keymaps = {
			view = {
				{ "n", "]h", function() vim.cmd("normal! ]c") end, { desc = "Next hunk" } },
				{ "n", "[h", function() vim.cmd("normal! [c") end, { desc = "Prev hunk" } },
			},
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
