local M = {}

-- On-save per-file checking is configured in lua/plugins/lint.lua.
-- Call this from a project's .nvim.lua to bind a full-project check to a key:
--   local cppcheck = require("custom.cppcheck")
--   vim.keymap.set("n", "<leader>5", function()
--       cppcheck.check_project(vim.fn.getcwd() .. "/build/compile_commands.json")
--   end, { desc = "cppcheck full project" })
function M.check_project(compile_db)
	vim.notify("Running cppcheck on full project...", vim.log.levels.INFO)
	local lines = vim.fn.systemlist(
		"cppcheck --project=" .. compile_db ..
		" --enable=warning,style,performance,information" ..
		" --inline-suppr --quiet --suppress=missingIncludeSystem" ..
		" '--template={file}:{line}:{column}: [{id}] {severity}: {message}' 2>&1"
	)
	local qf = {}
	for _, line in ipairs(lines) do
		local file, lnum, col, id, sev, msg =
			line:match("^(.-):(%d+):(%d+): %[(.-)%] (%S+): (.+)$")
		if file then
			table.insert(qf, {
				filename = file, lnum = tonumber(lnum), col = tonumber(col),
				text = "[" .. id .. "] " .. sev .. ": " .. msg,
				type = sev == "error" and "E" or "W",
			})
		end
	end
	vim.fn.setqflist(qf)
	vim.cmd("copen")
	vim.notify("cppcheck: " .. #qf .. " issues", vim.log.levels.INFO)
end

return M
