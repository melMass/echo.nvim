local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

return require("telescope").register_extension({
	exports = {
		sounds = function(opts)
			opts = opts or {}

			pickers
				.new(opts, {
					prompt_title = "🔊 Echo builtin sounds",
					initial_mode = opts.initial_mode or "normal",
					finder = finders.new_table({
						results = require("echo").list_builtin_sounds(),
					}),
					sorter = sorters.get_generic_fuzzy_sorter(opts),

					---@diagnostic disable-next-line: unused-local
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							local selection = action_state.get_selected_entry()
							require("echo").play_builtin(selection[1])
						end)
						return true
					end,
				})
				:find()
		end,
	},
})
