return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.1",
		config = function()
			local actions = require("telescope.actions")

			local select_one_or_multi = function(prompt_bufnr)
				-- custom function to enable multi select with tab opening
				local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
				local multi = picker:get_multi_selection()
				if not vim.tbl_isempty(multi) then
					require("telescope.actions").close(prompt_bufnr)
					for _, j in pairs(multi) do
						if j.path ~= nil then
							if j.lnum ~= nil then
								vim.cmd(string.format("%s +%s %s", "tabnew", j.lnum, j.path))
							else
								vim.cmd(string.format("%s %s", "tabnew", j.path))
							end
						end
					end
				else
					require("telescope.actions").select_tab(prompt_bufnr)
				end
			end

			local scroll_git_preview = function(self, direction)
				-- scroll function to enable scrolling of git-preview
				if not self.state then
					return
				end

				local input = direction > 0 and [[]] or [[]]
				local count = math.abs(direction)

				vim.api.nvim_buf_call(self.state.termopen_bufnr, function()
					vim.cmd([[normal! ]] .. count .. input)
				end)
			end

			local open_commit_in_tab = function(prompt_bufnr)
				local entry = require("telescope.actions.state").get_selected_entry()
				if not entry then
					return
				end

				actions.close(prompt_bufnr)

				local hash = entry.value:match("^(%S+)")
				local diff_output = vim.fn.systemlist({
					"git",
					"--no-pager",
					"show",
					"--stat",
					"--patch",
					hash,
				})

				vim.cmd("tabnew")
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff_output)
				pcall(vim.api.nvim_buf_set_name, buf, "commit://" .. hash)
				vim.bo[buf].buftype = "nofile"
				vim.bo[buf].bufhidden = "wipe"
				vim.bo[buf].modifiable = false
				vim.bo[buf].filetype = "diff"
			end

			require("telescope").setup({
				defaults = {
					layout_config = {
						scroll_speed = 1,
					},

					mappings = {
						i = {
							["<Esc>"] = actions.close,
							["<C-h>"] = actions.which_key,

							-- able to open multiple tabs at once
							["<C-t>"] = select_one_or_multi,

							-- reconfigure to be consistent with up/down
							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,

							-- preview window scrolling
							["<Up>"] = actions.preview_scrolling_up,
							["<Down>"] = actions.preview_scrolling_down,
							["<Left>"] = actions.preview_scrolling_left,
							["<Right>"] = actions.preview_scrolling_right,
						},
					},
				},

				pickers = {
					diagnostics = {
						previewer = require("telescope.previewers").new_buffer_previewer({
							define_preview = function(self, entry, status)
								local message = (
									type(entry.value) == "table" and (entry.value.message or entry.value.text)
								)
									or (type(entry.value) == "string" and entry.value)
									or tostring(entry.value or "")
								local width = vim.api.nvim_win_get_width(status.preview_win)
								local sep = string.rep("\xe2\x94\x80", width)

								local header = {}
								for _, line in ipairs(vim.split(message, "\n")) do
									while #line > width do
										local break_pos = line:sub(1, width):match("^.*%s()")
										if break_pos and break_pos > 1 then
											table.insert(header, line:sub(1, break_pos - 2))
											line = line:sub(break_pos)
										else
											table.insert(header, line:sub(1, width))
											line = line:sub(width + 1)
										end
									end
									table.insert(header, line)
								end
								while #header < 3 do
									table.insert(header, "")
								end
								table.insert(header, sep)
								table.insert(header, "")

								local filename = entry.filename or entry.path
								local file_lines = {}
								if filename then
									local ok, lines = pcall(vim.fn.readfile, filename)
									if ok then
										file_lines = lines
									end
								end

								local all_lines = {}
								vim.list_extend(all_lines, header)
								vim.list_extend(all_lines, file_lines)
								vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, all_lines)

								local ft = (filename and vim.filetype.match({ filename = filename })) or ""
								if ft ~= "" then
									vim.bo[self.state.bufnr].filetype = ft
								end

								local target = (entry.lnum or 1) + #header
								pcall(vim.api.nvim_win_set_cursor, status.preview_win, { target, entry.col or 0 })
							end,
						}),
					},
					git_commits = {
						git_command = {
							"git",
							"log",
							"--pretty=format:%h | %ad | %s%n",
							"--date=format:%Y-%m-%d %H:%M",
						},
						mappings = {
							i = { ["<CR>"] = open_commit_in_tab },
						},
						previewer = require("telescope.previewers").new_termopen_previewer({
							get_command = function(entry)
								local hash = entry.value:match("^(%S+)")
								return {
									"git",
									"--no-pager", -- this is needed to support preview scrolling
									"show",
									"--color=always",
									"--stat",
									"--patch",
									hash,
								}
							end,
							scroll_fn = scroll_git_preview,
						}),
					},
					git_bcommits = {
						mappings = {
							i = { ["<CR>"] = open_commit_in_tab },
						},
					},
					git_branches = {
						mappings = {
							i = {
								["<C-d>"] = actions.preview_scrolling_down,
							},
						},
						previewer = require("telescope.previewers").new_termopen_previewer({
							get_command = function(entry)
								return {
									"git",
									"--no-pager", -- this is needed to support preview scrolling
									"log",
									"--max-count=1000",
									"--pretty=format:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset",
									"--abbrev-commit",
									"--date=relative",
									entry.value,
								}
							end,
							scroll_fn = scroll_git_preview,
						}),
					},
				},
				-- TODO: I want to use git status better (add, remove, commit, push)
				-- TODO: I want to see diff between different branches
			})
			require("telescope").load_extension("live_grep_args")
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",

			-- for better performance use C-impl of fzf
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				-- This will not install any breaking changes.
				-- For major updates, this must be adjusted manually.
				version = "^1.0.0",
			},
		},
	},
}
