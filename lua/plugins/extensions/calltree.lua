-- Helpers that read litee-calltree internal state to add behaviors
-- litee doesn't expose as config options. Guards against API changes.
-- auto_highlight is disabled in litee setup so we own CursorMoved for both directions.
local M = {}

local function get_calltree_state()
	local ok, lib_state = pcall(require, "litee.lib.state")
	if not ok then return nil end
	local tab = vim.api.nvim_win_get_tabpage(0)
	local state = lib_state.get_state(tab)
	if state == nil or state["calltree"] == nil then return nil end
	return state["calltree"]
end

function M.ctx()
	local ct = get_calltree_state()
	if ct == nil then return nil end
	if ct.win == nil or not vim.api.nvim_win_is_valid(ct.win) then return nil end
	if ct.tree == nil then return nil end

	local ok, lib_tree = pcall(require, "litee.lib.tree")
	if not ok then return nil end

	local cursor = vim.api.nvim_win_get_cursor(ct.win)
	local node = lib_tree.marshal_line(cursor, ct.tree)

	return {
		win = ct.win,
		tree = ct.tree,
		direction = ct.direction,
		invoking_win = ct.invoking_win,
		node = node,
	}
end

local function find_source_win(ctx)
	if ctx.invoking_win ~= nil and vim.api.nvim_win_is_valid(ctx.invoking_win) then
		local ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(ctx.invoking_win), "filetype")
		if ft ~= "calltree" then return ctx.invoking_win end
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype")
		if ft ~= "calltree" then return win end
	end
	return nil
end

-- Load a URI into a buffer with proper filetype detection (triggers TreeSitter).
-- Uses bufadd/bufload + nvim_buf_call to avoid changing the current window,
-- which would otherwise fire spurious CursorMoved events for the calltree.
local function load_uri(uri)
	local fname = vim.uri_to_fname(uri)
	local buf = vim.fn.bufadd(fname)
	if vim.fn.bufloaded(buf) == 0 then
		vim.fn.bufload(buf)
	end
	if vim.api.nvim_buf_get_option(buf, "filetype") == "" then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("filetype detect")
		end)
	end
	return buf
end

-- Open the caller file at the call site in the source window.
-- focus = true moves the cursor into the source window afterwards.
function M.goto_incoming_call_site(ctx, focus)
	local node = ctx.node
	if node == nil or node.depth == 0 then return end
	if node.references == nil or #node.references == 0 then return end
	if node.location == nil or node.location.uri == nil then return end

	local ref = node.references[1]
	if ref == nil or ref["start"] == nil or ref["start"].line < 0 then return end

	local target_win = find_source_win(ctx)
	if target_win == nil then return end

	local buf = load_uri(node.location.uri)
	local line_count = vim.api.nvim_buf_line_count(buf)
	local line = ref["start"].line + 1
	if line > line_count then return end

	vim.api.nvim_win_set_buf(target_win, buf)
	vim.api.nvim_win_set_cursor(target_win, { line, ref["start"].character })

	if focus then
		vim.api.nvim_set_current_win(target_win)
	end
end

-- Move the source window cursor to the call site for an outgoing node.
-- Replaces litee's auto_highlight cursor-move for the "to" direction.
local function preview_outgoing(ctx)
	local node = ctx.node
	if node == nil or node.depth == 0 then return end
	if node.references == nil or #node.references == 0 then return end
	local ref = node.references[1]
	if ref == nil or ref["start"] == nil or ref["start"].line < 0 then return end

	local win = ctx.invoking_win
	if win == nil or not vim.api.nvim_win_is_valid(win) then return end

	local line = ref["start"].line + 1
	if line > vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)) then return end
	vim.api.nvim_win_set_cursor(win, { line, 0 })
end

local _last_preview_key = nil

-- CursorMoved callback: preview the call site in the source window.
-- Handles both incoming (opens caller file) and outgoing (moves cursor in invoking buf).
function M.preview()
	local ctx = M.ctx()
	if ctx == nil or ctx.node == nil then return end
	local key = ctx.node.key
	if key == _last_preview_key then return end
	_last_preview_key = key

	if ctx.direction == "from" then
		M.goto_incoming_call_site(ctx, false)
	elseif ctx.direction == "to" then
		preview_outgoing(ctx)
	end
end

-- ENTER: focus the call site and close the panel.
function M.on_enter()
	local ctx = M.ctx()
	if ctx == nil then
		vim.cmd("LTJumpCalltree")
		vim.cmd("LTCloseCalltree")
		return
	end

	if ctx.direction == "from" and ctx.node ~= nil and ctx.node.depth ~= 0 then
		M.goto_incoming_call_site(ctx, true)
		vim.cmd("LTCloseCalltree")
	else
		vim.cmd("LTJumpCalltree")
		vim.cmd("LTCloseCalltree")
	end
end

-- Focus the calltree panel window. Returns true if found and focused.
function M.focus_panel()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.api.nvim_buf_get_option(buf, "filetype") == "calltree" then
			vim.api.nvim_set_current_win(win)
			return true
		end
	end
	return false
end

return M
