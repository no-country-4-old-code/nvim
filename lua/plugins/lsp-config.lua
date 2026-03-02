-- config of my lsp
-- https://github.com/mrcjkb/rustaceanvim?tab=readme-ov-file
return {
	{
		"neovim/nvim-lspconfig",
		enable = true,
		config = function()
			-- Rust
			on_attach =
				function(client, bufnr)
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end, vim.lsp.config("rust_analyzer", {
					settings = {
						["rust-analyzer"] = {
							cargo = { allFeatures = true },
							checkOnSave = true,
							check = {
								command = "clippy",
							},
						},
					},
				})
			vim.lsp.enable("rust_analyzer")

			-- C / C++
			vim.lsp.enable("clangd")

			-- C#
			vim.lsp.enable("omnisharp")

			-- Python
			vim.lsp.enable("pyright")
		end,
	},
}
