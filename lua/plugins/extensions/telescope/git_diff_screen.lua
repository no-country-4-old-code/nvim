local M = {}

-- opts = { cmd = { ... }, name = "..." }
M.open_as_tab = function(opts)
	local output = vim.fn.systemlist(opts.cmd)

	vim.cmd("tabnew")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
	if opts.name then
		pcall(vim.api.nvim_buf_set_name, buf, opts.name)
	end
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "diff"
end

return M
