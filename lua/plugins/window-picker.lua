return {
	{
		"s1n7ax/nvim-window-picker",
		version = "2.*",
		config = function()
			require("window-picker").setup({
				hint = "floating-letter",
				selection_chars = "FJDKSLAGHRUEIWOCM",
				filter_rules = {
					include_current_win = false,
					autoselect_one = true,
					bo = {
						filetype = { "notify", "noice" },
						buftype = { "terminal", "quickfix" },
					},
				},
			})

			vim.keymap.set("n", "<leader>w", function()
				local win = require("window-picker").pick_window()
				if win then
					vim.api.nvim_set_current_win(win)
				end
			end, { desc = "Pick window to jump to" })
		end,
	},
}
