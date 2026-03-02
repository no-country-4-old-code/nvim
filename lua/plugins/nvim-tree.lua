return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", opts = {} },
	},
	config = function()
		local function my_on_attach(bufnr)
			local api = require("nvim-tree.api")

			local function opts(desc)
				return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
			end

			local function scroll_preview(lines)
				local tree_win = vim.api.nvim_get_current_win()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if win ~= tree_win then
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
							vim.api.nvim_win_call(win, function()
								vim.cmd("normal! " .. math.abs(lines) .. (lines > 0 and "j" or "k"))
							end)
							break
						end
					end
				end
			end

			-- default mappings
			api.config.mappings.default_on_attach(bufnr)

			-- custom mappings
			vim.keymap.set("n", "h", api.tree.change_root_to_parent, opts("Open parent"))
			vim.keymap.set("n", "l", api.tree.change_root_to_node, opts("Close parent"))
			vim.keymap.set("n", "<Space>", api.node.open.preview, opts("Preview file"))
			vim.keymap.set("n", "<Down>", function() scroll_preview(1) end, opts("Scroll preview down"))
			vim.keymap.set("n", "<Up>", function() scroll_preview(-1) end, opts("Scroll preview up"))
			vim.keymap.set("n", "t", api.node.open.tab, opts("Open: New Tab"))
			vim.keymap.set("n", "v", api.node.open.vertical, opts("Open: Vertical"))
			vim.keymap.set("n", "x", api.node.open.horizontal, opts("Open: Horizontal"))
			vim.keymap.set("n", "q", api.tree.close, opts("Close Dialog"))
			vim.keymap.set("n", "<ESC>", api.tree.close, opts("Close Dialog"))
			vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
		end

		-- migth not be rendered correctly on WSL
		require("nvim-web-devicons").setup({
			--	strict = true,
			override_by_extension = {
				["lua"] = {
					icon = "L",
					color = "#81e043",
					name = "LUA",
				},
			},
		})

		require("nvim-tree").setup({
			view = { adaptive_size = true },
			on_attach = my_on_attach,

			actions = {
				open_file = {
					quit_on_open = true,
				},
			},

			git = {
				enable = false,
			},
			renderer = {
				icons = {
					show = {
						file = false, -- enable here again if not WSL
						folder = false,
						folder_arrow = false,
						git = false,
					},
					glyphs = {
						folder = {
							default = "F",
						},
					},
				},
			},
		})
	end,
}
