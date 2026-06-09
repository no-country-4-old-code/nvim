return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
			end

			map("n", "]h", gs.next_hunk, "Next hunk (git)")
			map("n", "[h", gs.prev_hunk, "Prev hunk (git)")
			map({ "n", "v" }, "<leader>ga", ":Gitsigns stage_hunk<CR>", "Stage hunk (git)")
			map({ "n", "v" }, "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", "Unstage hunk (git)")
			map("n", "<leader>gA", gs.stage_buffer, "Stage entire file (git)")
			map("n", "<leader>gU", gs.reset_buffer_index, "Unstage entire file (git)")
			map("n", "<leader>gp", gs.preview_hunk, "Preview hunk (git)")
		end,
	},
}
