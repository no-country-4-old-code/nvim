return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			keymap = {
				preset = "default",
				["<Tab>"] = {
					-- accept via pressing Tab
					function(cmp)
						if cmp.is_menu_visible() then
							return cmp.accept({ select = true })
						end
					end,
					"fallback",
				},
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
}
