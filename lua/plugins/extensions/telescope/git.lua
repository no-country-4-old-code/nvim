local telescope = require("telescope.builtin")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")

local M = {}

function M.git_commits()
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

function M.git_branches()
	telescope.git_branches({
		previewer = previewers.new_termopen_previewer({
			get_command = function(entry)
				local branch = entry.value
				local hint = "  <CR> diff to current  |  <C-o> checkout"
				local cmd = "echo 'Recent commits:'"
					.. " && git log --oneline --color=always -10 "
					.. branch
					.. " && echo '' && echo 'Changed vs HEAD:'"
					.. " && git diff --stat --color=always HEAD.."
					.. branch
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
			map({ "i", "n" }, "<C-o>", function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				vim.cmd("Git checkout " .. selection.value)
			end)
			return true
		end,
	})
end

function M.history_diff_range()
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

return M
