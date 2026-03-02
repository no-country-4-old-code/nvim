-- easy installation of external tools like lsp with mason !
return {
	{ "mason-org/mason.nvim", opts = {} },

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"rust_analyzer",
				"clangd",
				"omnisharp",
				"pyright",
			},
		},
		enable = true,
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
}
