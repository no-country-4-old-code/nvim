return {
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {
			focus = true,
			win = {
				position = "left",
			},
			keys = {
				["<esc>"] = "close",
				["<cr>"] = "jump_close",
			},
			modes = {
				symbols = {
					win = {
						position = "left",
					},
				},
			},
		},
	},
}
