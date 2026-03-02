return {
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			-- Based on (but sligthly modified):
			-- Bubbles config for lualine
			-- Author: lokesh-krishna
			-- MIT license, see LICENSE for more details.

			local colors = {
				blue = "#80a0ff",
				cyan = "#79dac8",
				black = "#080808",
				white = "#c6c6c6",
				red = "#ff5189",
				violet = "#d183e8",
				grey = "#303030",
			}

			local bubbles_theme = {
				normal = {
					a = { fg = colors.black, bg = colors.cyan },
					b = { fg = colors.white, bg = colors.grey },
					c = { fg = colors.white },
				},

				insert = { a = { fg = colors.black, bg = colors.blue } },
				visual = { a = { fg = colors.black, bg = colors.violet } },
				replace = { a = { fg = colors.black, bg = colors.red } },

				inactive = {
					a = { fg = colors.white, bg = colors.black },
					b = { fg = colors.white, bg = colors.black },
					c = { fg = colors.white },
				},
			}

			require("lualine").setup({
				options = {
					theme = bubbles_theme,
					component_separators = "",
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
					lualine_b = { "filename" },
					lualine_c = {
						"%=", --[[ add your center components here in place of this comment ]]
					},
					lualine_x = {},
					lualine_y = { "branch" }, -- !! under WSL the branch might not update properly
					lualine_z = {
						{ "progress", separator = { right = "" }, left_padding = 2 },
					},
				},
				inactive_sections = {
					lualine_a = { "filename" },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "progress" },
				},
				tabline = {
				lualine_a = {
					{
						"tabs",
						mode = 1, -- filename only, no path
						separator = { left = "", right = "" },
						max_length = function() return vim.o.columns end,
					},
				},
			},
				extensions = {},
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
}
