return {
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {
			focus = true,
			win = {
				position = "left",
				size = 50,
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
