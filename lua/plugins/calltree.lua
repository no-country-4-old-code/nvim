return {
	{
		"ldelossa/litee.nvim",
		pin = true,
		config = function()
			require("litee.lib").setup({
				notify = { enabled = false },
				panel = {
					orientation = "left",
					panel_size = 50,
				},
			})
		end,
	},
	{
		"ldelossa/litee-calltree.nvim",
		pin = true,
		dependencies = { "ldelossa/litee.nvim" },
		config = function()
			require("litee.calltree").setup({
				on_open = "panel",
				auto_highlight = false, -- we handle CursorMoved preview for both directions
				keymaps = {
					expand = "l",
					collapse = "h",
				},
			})

			-- Install ESC/ENTER overrides via vim.schedule so they run after litee's
			-- synchronous buffer.lua keymap setup (which would otherwise overwrite them).
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "calltree",
				callback = function(ev)
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(ev.buf) then return end
						local ct = require("plugins.extensions.calltree")
						local o = { buffer = ev.buf, silent = true }
						vim.keymap.set("n", "<Esc>", ct.on_close, o)
						vim.keymap.set("n", "<CR>", ct.on_close, o)
						vim.api.nvim_create_autocmd("CursorMoved", {
							buffer = ev.buf,
							callback = ct.preview,
						})
					end)
				end,
			})
		end,
	},
}
