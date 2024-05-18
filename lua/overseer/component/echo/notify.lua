local constants = require("overseer.constants")
local util = require("overseer.util")
local echo = require("echo")
local STATUS = constants.STATUS

--TODO: expose status / sound mapping as params

---@alias overseer.Status "PENDING"|"RUNNING"|"CANCELED"|"SUCCESS"|"FAILURE"|"DISPOSED"

return {
	desc = "Basic component to bridge echo and overseer, mimicking the notify one",
	params = {
		statuses = {
			type = "list",
			subtype = {
				type = "enum",
				choices = STATUS.values,
			},
			default = { STATUS.RUNNING, STATUS.FAILURE, STATUS.SUCCESS },
			desc = "List of statuses to notify on",
		},
		on_change = {
			desc = "Only notify when task status changes from previous value",
			long_desc = "This is mostly used when a task is going to be restarted, and you want notifications only when it goes from SUCCESS to FAILURE, or vice-versa",
			type = "boolean",
			default = true,
		},
	},
	editable = true,
	serializable = false,
	constructor = function(params)
		if type(params.statuses) == "string" then
			params.statuses = { params.statuses }
		end

		local lookup = util.list_to_map(params.statuses)
		return {
			last_status = nil,
			---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
			---@param result table A result table.
			on_complete = function(self, task, status, result)
				-- Called when the task has reached a completed state.
				if lookup[status] then
					if params.on_change then
						if status == self.last_status then
							return
						end
						self.status = status
					end
					--
					if status == "SUCCESS" then
						echo.play_sound("builtin:COMPLETE_3")
					elseif status == "RUNNING" then
						echo.play_sound("builtin:TAB_2")
					elseif status == "FAILURE" then
						echo.play_sound("builtin:ERROR_2")
					else
						echo.play_sound("builtin:NOTIFICATION_2")
					end
				end
			end,
		}
	end,
}
