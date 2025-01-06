local native = nil

local register_callback = function(event, sound, amplify)
	local callback = function()
		if event == "BufWrite" then
			local buf = vim.api.nvim_get_current_buf()
			local buf_modified = vim.api.nvim_get_option_value("modified", { buf = buf })
			if buf_modified then
				native.play_sound(sound, amplify)
			end
		else
			native.play_sound(sound, amplify)
		end
	end
	return function()
		callback()
	end
end

-- WIP "buffer" audio player
local setupAudioBufferUI = function(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })

	local audio_file = vim.api.nvim_buf_get_name(bufnr)
	local ui_elements = {
		"Audio File: " .. audio_file,
		"Play [p] Pause [p] Stop [s] Seek fwd [l] Seek bck [h]",
	}
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, ui_elements)

	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	local mappings = {
		["p"] = string.format("require('echo').play_sound(\"%s\")", audio_file:gsub("\\", "/")),
	}
	for key, command in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(
			bufnr,
			"n",
			key,
			"<cmd>lua " .. command .. "<CR>",
			{ noremap = true, silent = true }
		)
	end
	native.play_sound(audio_file)
end

return {
	setup = function(opts)
		local native = require("echo_native")
		local success, result = pcall(require, "echo_native")

		if not success then
			local build_utils = require("echo.build-utills")
			build_utils.download_binary()
			local resuccess, reresult = pcall(require, "echo_native")
			if not resuccess then
				vim.notify(
					"echo.nvim: Failed to load the native library. Try running `:Echo install` or read the troubleshooting guide.",
					vim.log.levels.ERROR,
					{ title = "echo.nvim" }
				)
				return
			end
			native = resuccess
		end

		opts = opts or {}
		opts = native.setup(opts)
		local events = opts.events or {}
		-- NOTE: register demo sound/events
		if opts.demo then
			table.insert(events, {
				BufRead = { path = "builtin:EXPAND", amplify = 1.0 },
				BufWrite = { path = "builtin:SUCCESS_2", amplify = 1.0 },
				CursorMovedI = { path = "builtin:BUTTON_3", amplify = 0.45 },
				ExitPre = { path = "builtin:COMPLETE_3", amplify = 1.0 },
				InsertLeave = { path = "builtin:NOTIFICATION_5", amplify = 0.5 },
				-- LazyReload = { path = "builtin:NOTIFICATION_6", amplify = 0.2 },
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
					callback = register_callback(eventName, sound.path, sound.amplify),
				})
			end
		end
		-- TODO: expose this as an option
		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			pattern = { "*.mp3", "*.wav", "*.flac" },
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_set_option_value("filetype", "audio", { buf = buf })
			end,
		})
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "audio",
			callback = function()
				setupAudioBufferUI(vim.fn.bufnr())
			end,
		})
	end,
	play_sound = native.play_sound,
	options = native.options,
	play_builtin = function(name)
		native.play_sound(string.format("builtin:%s", name))
	end,
	list_builtin_sounds = native.list_builtin_sounds,
}
