local git_diff_screen = require("plugins.extensions.telescope.git_diff_screen")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local scroll_git_preview = function(self, direction)
	-- scroll function to enable scrolling of git-preview
	if not self.state then
		return
	end

	local input = direction > 0 and [[]] or [[]]
	local count = math.abs(direction)

	vim.api.nvim_buf_call(self.state.termopen_bufnr, function()
		vim.cmd([[normal! ]] .. count .. input)
	end)
end

local diff = {}

diff.to_commit = function(opts)
	opts = opts or {}

	local previewer = previewers.new_termopen_previewer({
		get_command = function(entry)
			local hash = entry.value:match("^(%S+)")
			return {
				"git",
				"--no-pager",
				"diff",
				"--color=always",
				"--stat",
				"--patch",
				hash,
				"HEAD",
			}
		end,
		scroll_fn = scroll_git_preview,
	})

	pickers
		.new(opts, {
			prompt_title = "Git Diff to Commit",

			finder = finders.new_oneshot_job({
				"git",
				"log",
				"--pretty=format:%h | %ad | %s",
				"--date=format:%Y-%m-%d %H:%M",
			}, {
				entry_maker = function(line)
					local hash = line:match("^(%S+)")
					return {
						value = hash,
						display = line,
						ordinal = line,
					}
				end,
			}),

			sorter = conf.generic_sorter(opts),
			previewer = previewer,

			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					if not entry then
						return
					end

					actions.close(prompt_bufnr)

					local hash = entry.value
					git_diff_screen.open_as_tab({
						cmd = { "git", "--no-pager", "diff", "--stat", "--patch", hash, "HEAD" },
						name = "diff://" .. hash .. "..HEAD",
					})
				end)
				return true
			end,
		})
		:find()
end

return diff
