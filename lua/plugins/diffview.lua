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
				{
					"n", "<leader>ga",
					function() require("gitsigns").stage_hunk() end,
					{ desc = "Stage hunk (git)" },
				},
				{
					"v", "<leader>ga",
					function()
						local l1 = vim.fn.line("'<")
						local l2 = vim.fn.line("'>")
						require("gitsigns").stage_hunk({ l1, l2 })
					end,
					{ desc = "Stage selected lines (git)" },
				},
				{
					"n", "<leader>gu",
					function() require("gitsigns").undo_stage_hunk() end,
					{ desc = "Unstage hunk (git)" },
				},
				{ "n", "<leader>ginfo", function() end, { desc = "Diffview status: ga=stage hunk | gu=unstage hunk | gA=stage file | gU=unstage file | S=stage all | U=unstage all | - toggle stage | X=discard" } },
				{ "n", "zo", "zo", { desc = "Open fold" } },
				{ "n", "zr", "zr", { desc = "Open all folds one level" } },
				{ "v", "<leader>gp", ":diffput<CR>", { desc = "Push selected lines to other panel" } },
				{ "v", "<leader>gl", ":diffget<CR>", { desc = "Get selected lines from other panel" } },
			},
			file_panel = {
				{ "n", "<leader>ga", "<Cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk under cursor (git)" } },
				{ "n", "<leader>gA", function() require("gitsigns").stage_buffer() end, { desc = "Stage entire file (git)" } },
				{ "n", "<leader>gU", function() require("gitsigns").reset_buffer_index() end, { desc = "Unstage entire file (git)" } },
				{ "n", "<leader>ginfo", function() end, { desc = "File panel: - toggle stage | S stage all | U unstage all | X discard | gA stage file | gU unstage file" } },
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
