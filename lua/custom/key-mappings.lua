local M = {}

function M.setup()
	-- modules
	local telescope = require("telescope.builtin")

	-- helper
	local function show_keymaps()
		telescope.keymaps({
			filter = function(km)
				return km.desc ~= nil and km.desc ~= ""
			end,
		})
	end

	local function find_files()
		telescope.find_files({
			sorter = require("telescope.sorters").get_substr_matcher(),
		})
	end

	local function open_file_tree()
		local tree = require("nvim-tree.api")
		tree.tree.toggle({ find_file = true, focus = true })
	end

	-- general
	vim.keymap.set("n", "<leader>h", show_keymaps, { desc = "Show keymaps" })

	-- navigation
	vim.keymap.set("n", "<leader>ft", open_file_tree, { desc = "Open file tree (navigation)" })
	vim.keymap.set("n", "<leader>fj", telescope.jumplist, { desc = "Browse jump history (navigation)" })
	vim.keymap.set("n", "<leader>ff", find_files, { desc = "Search by file name (navigation)" })
	vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Search in file contents (navigation)" })
	vim.keymap.set("n", "<leader>fr", telescope.registers, { desc = "Browse registers (navigation)" })
	vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Browse open buffers (navigation)" })

	-- code navigation via (lsp)
	vim.keymap.set("n", "<leader>cl", telescope.diagnostics, { desc = "Browse diagnostics (linter) (code)" })
	vim.keymap.set("n", "<leader>cd", telescope.lsp_definitions, { desc = "Go to definition (code)" })
	vim.keymap.set("n", "<leader>cu", telescope.lsp_references, { desc = "Find usages / references (code)" })
	vim.keymap.set("n", "<leader>ci", telescope.lsp_incoming_calls, { desc = "Callstack up (who calls this) (code)" })
	vim.keymap.set(
		"n",
		"<leader>co",
		telescope.lsp_outgoing_calls,
		{ desc = "Callstack down (what this calls) (code)" }
	)

	-- git
	vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen master<CR>", { desc = "Open diff vs master (git)" })
	vim.keymap.set("n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Close diffview (git)" })

	local function git_commits()
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		local previewers = require("telescope.previewers")
		telescope.git_commits({
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					local hash = entry.value
					local hint = "  <CR> diff to current  |  <C-h> commit changes  |  <C-o> checkout"
					local cmd = "git log -1 "
						.. hash
						.. " && echo '' && echo 'Files changed:'"
						.. " && git diff-tree --no-commit-id -r --color=always --stat "
						.. hash
						.. " && printf '\\n"
						.. string.rep("-", 50)
						.. "\\n\\n"
						.. hint
						.. "\\n'"
					return { "sh", "-c", cmd }
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				map({ "i", "n" }, "<CR>", function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewOpen " .. selection.value)
				end)
				map({ "i", "n" }, "<C-h>", function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewFileHistory --range=" .. selection.value .. "^.." .. selection.value)
				end)
				map({ "i", "n" }, "<C-o>", function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("Git checkout " .. selection.value)
				end)
				return true
			end,
		})
	end
	vim.keymap.set(
		"n",
		"<leader>gc",
		git_commits,
		{ desc = "Browse git commits (CR=diff vs HEAD | C-h=file overview | C-o=checkout)" }
	)
	vim.keymap.set("n", "<leader>gf", telescope.git_bcommits, { desc = "Browse git commits for this file" })

	local function git_branches()
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		local previewers = require("telescope.previewers")
		telescope.git_branches({
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					local branch = entry.value
					local hint = "  <CR> diff to current  |  <C-o> checkout"
					local cmd = "echo 'Recent commits:'"
						.. " && git log --oneline --color=always -10 " .. branch
						.. " && echo '' && echo 'Changed vs HEAD:'"
						.. " && git diff --stat --color=always HEAD.." .. branch
						.. " && printf '\\n" .. string.rep("-", 50) .. "\\n\\n" .. hint .. "\\n'"
					return { "sh", "-c", cmd }
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				map({ "i", "n" }, "<CR>", function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewOpen " .. selection.value)
				end)
				map({ "i", "n" }, "<C-o>", function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("Git checkout " .. selection.value)
				end)
				return true
			end,
		})
	end
	vim.keymap.set("n", "<leader>gb", git_branches, { desc = "Browse git branches (CR=diff vs current | C-o=checkout)" })
	vim.keymap.set("n", "<leader>gs", "<cmd>DiffviewOpen<CR>", { desc = "Open git status / working tree diff (git)" })

	-- history
	vim.keymap.set("n", "<leader>hr", "<cmd>DiffviewFileHistory<CR>", { desc = "View repo history (history)" })
	vim.keymap.set("n", "<leader>hf", "<cmd>DiffviewFileHistory %<CR>", { desc = "View file history (history)" })

	local function history_diff_range()
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		local previewers = require("telescope.previewers")

		telescope.git_commits({
			prompt_title = "Diff Range: FROM commit",
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					return { "sh", "-c", "git show --stat --color=always " .. entry.value }
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				map({ "i", "n" }, "<CR>", function()
					local from = action_state.get_selected_entry().value
					actions.close(prompt_bufnr)
					vim.schedule(function()
						telescope.git_commits({
							prompt_title = "Diff Range: TO commit (from " .. from:sub(1, 7) .. ")",
							previewer = previewers.new_termopen_previewer({
								get_command = function(entry)
									return { "sh", "-c", "git show --stat --color=always " .. entry.value }
								end,
							}),
							attach_mappings = function(prompt_bufnr2, map2)
								map2({ "i", "n" }, "<CR>", function()
									local to = action_state.get_selected_entry().value
									actions.close(prompt_bufnr2)
									vim.cmd("DiffviewOpen " .. from .. ".." .. to)
								end)
								return true
							end,
						})
					end)
				end)
				return true
			end,
		})
	end
	vim.keymap.set("n", "<leader>hd", history_diff_range, { desc = "View diff between 2 commits (history)" })

	-- debug
	vim.keymap.set("n", "<leader>db", function()
		require("dap").toggle_breakpoint()
	end, { desc = "Debug : Toggle breakpoint" })
	vim.keymap.set("n", "<leader>dc", function()
		require("dap").continue()
	end, { desc = "Debug : Continue / start" })
	vim.keymap.set("n", "<leader>dn", function()
		require("dap").step_over()
	end, { desc = "Debug : Step over" })
	vim.keymap.set("n", "<leader>di", function()
		require("dap").step_into()
	end, { desc = "Debug : Step into" })
	vim.keymap.set("n", "<leader>do", function()
		require("dap").step_out()
	end, { desc = "Debug : Step out" })
	vim.keymap.set("n", "<leader>dx", function()
		require("dap").terminate()
	end, { desc = "Debug : Terminate" })
	vim.keymap.set("n", "<leader>dp", function()
		require("dap").pause()
	end, { desc = "Debug : Pause" })
	vim.keymap.set("n", "<leader>dr", function()
		require("dap").restart()
	end, { desc = "Debug : Restart" })
	vim.keymap.set("n", "<leader>du", function()
		require("dapui").toggle()
	end, { desc = "Debug : Toggle UI" })
	vim.keymap.set("n", "<leader>de", function()
		require("dapui").eval()
	end, { desc = "Debug : Evaluate expression" })
	vim.keymap.set(
		"n",
		"<leader>dinfo",
		function() end,
		{ desc = "Debug : In side windows use e(dit), t(oggle), o(pen), c(ode), d(elete) " }
	)
	vim.keymap.set("n", "<leader>dw", function()
		require("dapui").elements.watches.add(vim.fn.expand("<cword>"))
	end, { desc = "Debug : Add word under cursor to watch" })

	-- tabs
	vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New empty tab (tabs)" })
	vim.keymap.set("n", "<leader>ts", "<cmd>tab split<CR>", { desc = "Open current file in new tab (tabs)" })
	vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab (tabs)" })

	-- window picker
	vim.keymap.set("n", "<leader>w", function()
		local win = require("window-picker").pick_window()
		if win then
			vim.api.nvim_set_current_win(win)
		end
	end, { desc = "Pick window to jump to" })

	-- ! keymaps used inside modules like 'telescope' or 'nvim-tree' are define in the related plugin-files
end

return M
