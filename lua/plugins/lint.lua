return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufWritePost" },
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			c = { "cppcheck" },
			cpp = { "cppcheck" },
		}
		lint.linters.cppcheck.args = {
			"--enable=warning",
			"--quiet",
			"--template={file}:{line}:{column}: {severity}: {message} [{id}]",
		}
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
