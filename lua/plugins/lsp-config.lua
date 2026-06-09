-- config of my lsp
-- https://github.com/mrcjkb/rustaceanvim?tab=readme-ov-file
return {
	{
		"neovim/nvim-lspconfig",
		enable = true,
		config = function()
			vim.diagnostic.config({
				signs = false, -- I do not like if line-numbers move on the side
				underline = true,
				virtual_text = true,
			})

			local function set_lsp_float_highlights()
				vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#ff69b4", bold = true })
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
			end
			set_lsp_float_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_lsp_float_highlights,
			})

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
