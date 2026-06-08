return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = {
		use_icons = false,
		keymaps = {
			view = {
				{ "n", "]h", function() vim.cmd("normal! ]c") end, { desc = "Next hunk" } },
				{ "n", "[h", function() vim.cmd("normal! [c") end, { desc = "Prev hunk" } },
				{ "n", "<leader>gp", function() vim.cmd("diffput") end, { desc = "Push hunk to other panel" } },
				{ "n", "<leader>gl", function() vim.cmd("diffget") end, { desc = "Get hunk from other panel" } },
				{ "n", "<leader>ginfo", function() end, { desc = "Diffview: ]h/[h hunks | ]x/[x conflicts | dh=get ours | dl=get theirs | gp=push | gl=get" } },
				{ "n", "zo", "zo", { desc = "Open fold" } },
				{ "n", "zr", "zr", { desc = "Open all folds one level" } },
				{ "v", "<leader>gp", ":diffput<CR>", { desc = "Push selected lines to other panel" } },
				{ "v", "<leader>gl", ":diffget<CR>", { desc = "Get selected lines from other panel" } },
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
