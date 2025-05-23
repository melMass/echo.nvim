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

local M = {}

M.setup = function(opts)
	local success, result = pcall(require, "echo_native")

	if not success then
		local build_utils = require("echo.build-utils")
		build_utils.download_binary()
		local resuccess, reresult = pcall(require, "echo_native")
		if not resuccess then
			vim.notify(
				"Failed to load the native library, if you just installed echo that's expected, you can now restart neovim.",
				vim.log.levels.INFO,
				{ title = "echo.nvim" }
			)
			error(reresult)
			return
		end
		native = reresult
	else
		native = result
	end

	if native == nil then
		print("No method could find the binary")
		return
	end

	M.play_sound = native.play_sound
	M.options = native.options
	M.list_builtin_sounds = native.list_builtin_sounds

	M.play_builtin = function(name)
		native.play_sound(string.format("builtin:%s", name))
	end

	opts = opts or {}
	opts = native.setup(opts)
	local events = opts.events or {}
	-- NOTE: register demo sound/events
	if opts.demo then
		local demo_events = {
			BufRead = { path = "builtin:EXPAND", amplify = 1.0 },
			BufWrite = { path = "builtin:SUCCESS_2", amplify = 1.0 },
			CursorMovedI = { path = "builtin:BUTTON_3", amplify = 0.45 },
			ExitPre = { path = "builtin:COMPLETE_3", amplify = 1.0 },
			InsertLeave = { path = "builtin:NOTIFICATION_5", amplify = 0.5 },
			-- LazyReload = { path = "builtin:NOTIFICATION_6", amplify = 0.2 },
		}

		for k, v in pairs(demo_events) do
			events[k] = v
		end
	end

	vim.api.nvim_create_augroup("echo_sound", {
		clear = true,
	})
	for name, event in pairs(events) do
		vim.api.nvim_create_autocmd(name, {
			group = "echo_sound",
			pattern = "*",
			callback = register_callback(name, event.path, event.amplify),
		})
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
end

M.play_sound = nil --native.play_sound,
M.options = nil --native.options,
M.play_builtin = nil
M.list_builtin_sounds = nil -- native.list_builtin_sounds

return M
