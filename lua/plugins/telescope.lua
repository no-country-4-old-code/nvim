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

			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
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
					git_commits = {
						git_command = {
							"git",
							"log",
							"--pretty=format:%h | %ad | %s%n",
							"--date=format:%Y-%m-%d %H:%M",
						},
						previewer = require("telescope.previewers").new_termopen_previewer({
							get_command = function(entry)
								local hash = entry.value:match("^(%S+)")
								return {
									"git",
									"show",
									"--color=always",
									"--stat",
									"--patch",
									hash,
								}
							end,
						}),
						-- TODO: Scrolling UP and DOWN does not work in this previewer
					},

					git_branches = {
						previewer = require("telescope.previewers").new_termopen_previewer({
							get_command = function(entry)
								-- extract hash from picker line
								local hash = entry.value:match("^(%S+)")
								return {
									"git",
									"log",
									hash,
									"--pretty=format:> %Cgreen%h%Creset ( %ad ) by %aN \n  %s\n",
									"--date=short",
								}
							end,
							-- TODO: I want to use git status better (add, remove, commit, push)
							-- TODO: I want to see diff between different branches
						}),
					},
				},
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
