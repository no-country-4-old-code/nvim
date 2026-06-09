local keymaps = require("custom.key-mappings")

return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = {
		use_icons = false,
		keymaps = {
			view = keymaps.diffview_view_keymaps,
			file_panel = keymaps.diffview_file_history_panel_keymaps,
			file_history_panel = keymaps.diffview_file_history_panel_keymaps,
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
