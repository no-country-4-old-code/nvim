return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufWritePost" },
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			c   = { "cppcheck" },
			cpp = { "cppcheck" },
		}

		-- Per-file cppcheck on save, using compile_commands.json when available.
		-- For a project-wide check bound to a key, see lua/custom/cppcheck.lua.
		lint.linters.cppcheck.append_fname = false
		lint.linters.cppcheck.args = {
			"--enable=warning,style,performance,information",
			"--language=c++",
			"--inline-suppr",
			"--quiet",
			"--suppress=missingIncludeSystem",
			"--template={file}:{line}:{column}: [{id}] {severity}: {message}",
			function()
				-- auto-discover compile_commands.json one directory below cwd
				local db = vim.fn.globpath(vim.fn.getcwd(), "*/compile_commands.json", 0, 1)
				if db[1] then return "--project=" .. db[1] end
			end,
			function()
				return "--file-filter=" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
			end,
		}

		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
