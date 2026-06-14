-- Helpers that read litee-calltree internal state to add behaviours
-- litee doesn't expose as config options. Guards against litee API changes.
-- auto_highlight is disabled in litee setup so we own CursorMoved for both directions.
local M = {}

-- ── litee state helpers ───────────────────────────────────────────────────────

local function get_calltree_state()
	local ok, lib_state = pcall(require, "litee.lib.state")
	if not ok then return nil end
	local state = lib_state.get_state(vim.api.nvim_win_get_tabpage(0))
	if state == nil or state["calltree"] == nil then return nil end
	return state["calltree"]
end

-- Returns the current call-tree context: panel window, tree handle, direction
-- ("from" = incoming / "to" = outgoing), invoking window, and cursor node.
function M.ctx()
	local ct = get_calltree_state()
	if ct == nil then return nil end
	if ct.win == nil or not vim.api.nvim_win_is_valid(ct.win) then return nil end
	if ct.tree == nil then return nil end

	local ok, lib_tree = pcall(require, "litee.lib.tree")
	if not ok then return nil end

	local cursor = vim.api.nvim_win_get_cursor(ct.win)
	return {
		win          = ct.win,
		tree         = ct.tree,
		direction    = ct.direction,
		invoking_win = ct.invoking_win,
		node         = lib_tree.marshal_line(cursor, ct.tree),
	}
end

-- ── source-window helpers ─────────────────────────────────────────────────────

-- Returns the best non-calltree window for previewing source.
local function find_source_win(ctx)
	local function is_source(win)
		return vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype") ~= "calltree"
	end
	if ctx.invoking_win ~= nil and vim.api.nvim_win_is_valid(ctx.invoking_win) and is_source(ctx.invoking_win) then
		return ctx.invoking_win
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if is_source(win) then return win end
	end
end

-- Loads uri into a buffer with filetype detection (needed for Tree-sitter).
-- Uses bufadd/bufload so the current window doesn't change (which would fire
-- spurious CursorMoved events in the calltree panel).
local function load_uri(uri)
	local buf = vim.fn.bufadd(vim.uri_to_fname(uri))
	if vim.fn.bufloaded(buf) == 0 then vim.fn.bufload(buf) end
	if vim.api.nvim_buf_get_option(buf, "filetype") == "" then
		vim.api.nvim_buf_call(buf, function() vim.cmd("filetype detect") end)
	end
	return buf
end

-- ── call-site preview ─────────────────────────────────────────────────────────

-- Returns references[1] after validating it has a usable range, else nil.
local function first_ref(node)
	if node == nil or node.depth == 0 then return nil end
	if node.references == nil or #node.references == 0 then return nil end
	local ref = node.references[1]
	if ref == nil or ref["start"] == nil or ref["start"].line < 0 then return nil end
	return ref
end

-- DFS: returns the parent node of the node whose key == target_key.
local function find_parent_node(root, target_key)
	if root == nil or root.children == nil then return nil end
	for _, child in ipairs(root.children) do
		if child.key == target_key then return root end
		local found = find_parent_node(child, target_key)
		if found then return found end
	end
end

-- For outgoing nodes: returns the parent (caller) node's file URI.
-- fromRanges are always positions in the caller's file, not the callee's.
local function outgoing_call_site_uri(ctx)
	local ok, lib_tree = pcall(require, "litee.lib.tree")
	if not ok then return nil end
	local tree = lib_tree.get_tree(ctx.tree)
	if tree == nil or tree.root == nil then return nil end
	local parent = find_parent_node(tree.root, ctx.node.key)
	if parent == nil or parent.location == nil then return nil end
	return parent.location.uri
end

-- Returns the file URI that contains the call-site for the current node.
--   incoming ("from"): the node's own location.uri  (node = the caller)
--   outgoing ("to"):   the parent node's uri         (parent = the caller)
local function call_site_uri(ctx)
	if ctx.direction == "from" then
		local loc = ctx.node.location
		return loc ~= nil and loc.uri or nil
	else
		return outgoing_call_site_uri(ctx)
	end
end

-- Loads uri and moves the source window's cursor to ref's call site.
local function show_call_site(ctx, uri, ref)
	if uri == nil then return end
	local target_win = find_source_win(ctx)
	if target_win == nil then return end
	local buf = load_uri(uri)
	local line = ref["start"].line + 1
	if line > vim.api.nvim_buf_line_count(buf) then return end
	vim.api.nvim_win_set_buf(target_win, buf)
	vim.api.nvim_win_set_cursor(target_win, { line, ref["start"].character })
end

local _last_preview_key = nil

-- CursorMoved callback: preview the call site in the source window.
-- Works for both directions; the only difference is which file holds the ranges.
function M.preview()
	local ctx = M.ctx()
	if ctx == nil or ctx.node == nil then return end
	local key = ctx.node.key
	if key == _last_preview_key then return end
	_last_preview_key = key
	local ref = first_ref(ctx.node)
	if ref == nil then return end
	show_call_site(ctx, call_site_uri(ctx), ref)
end

-- ── panel open / close ────────────────────────────────────────────────────────

-- Close the panel with autocmds suppressed.
-- litee's WinEnter/BufEnter extmark handler crashes when outgoing-call
-- fromRanges (positions in the caller's file) are applied as extmarks to the
-- callee's buffer that we loaded for preview.
function M.on_close()
	local saved = vim.o.eventignore
	vim.o.eventignore = "all"
	vim.cmd("LTCloseCalltree")
	vim.o.eventignore = saved
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
