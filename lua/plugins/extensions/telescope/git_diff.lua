local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- your custom scroll function (same as you referenced)
local function scroll_git_preview(self, direction)
	require("telescope.previewers.utils").scroll(self.state.bufnr, direction)
end

local diff = {}

diff.to_commit = function(opts)
	opts = opts or {}

	local previewer = previewers.new_termopen_previewer({
		get_command = function(entry)
			return {
				"git",
				"--no-pager",
				"log",
				"--max-count=1000",
				"--pretty=format:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset",
				"--abbrev-commit",
				"--date=relative",
				entry.value,
			}
		end,
		scroll_fn = scroll_git_preview,
	})

	pickers
		.new(opts, {
			prompt_title = "Git Branches (Custom)",

			finder = finders.new_oneshot_job({ "git", "branch", "--all", "--color=never" }, {
				entry_maker = function(line)
					local branch = line:gsub("^%*", ""):gsub("^%s+", "")
					return {
						value = branch,
						display = line,
						ordinal = branch,
					}
				end,
			}),

			sorter = conf.generic_sorter(opts),
			previewer = previewer,

			attach_mappings = function(prompt_bufnr, map)
				map("i", "<C-d>", actions.preview_scrolling_down)
				map("i", "<C-u>", actions.preview_scrolling_up)

				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local entry = action_state.get_selected_entry()
					vim.cmd("Git checkout " .. entry.value)
				end)

				return true
			end,
		})
		:find()
end

return diff
