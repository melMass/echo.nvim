local native = require("echo_native")

local register_callback = function(event, sound)
	local callback = function()
		if event == "BufWrite" then
			local buf = vim.api.nvim_get_current_buf()
			local buf_modified = vim.api.nvim_buf_get_option(buf, "modified")
			if buf_modified then
				native.play_sound(sound)
			end
		else
			native.play_sound(sound)
		end
	end
	return function()
		callback()
	end
end

return {
	setup = function(opts)
		opts = opts or {}
		opts = native.setup(opts)
		local events = opts.events or {}
		if opts.demo then
			table.insert(events, {
				BufRead = { path = "builtin:EXPAND", amplify = 1.0 },
				BufWrite = { path = "builtin:SUCCESS_2", amplify = 1.0 },
				CursorMovedI = { path = "builtin:BUTTON_3", amplify = 0.1 },
				ExitPre = { path = "builtin:COMPLETE_3", amplify = 1.0 },
				InsertLeave = { path = "builtin:NOTIFICATION_5", amplify = 0.2 },
			})
		end

		vim.api.nvim_create_augroup("echo_sound", {
			clear = true,
		})

		for _, event in ipairs(events) do
			for eventName, sound in pairs(event) do
				vim.api.nvim_create_autocmd(eventName, {
					group = "echo_sound",
					pattern = "*",
					callback = register_callback(eventName, sound.path),
				})
			end
		end
	end,
	play_sound = native.play_sound,
	options = native.options,
	play_builtin = function(name)
		native.play_sound(string.format("builtin:%s", name))
	end,
	list_builtin_sounds = native.list_builtin_sounds,
}
