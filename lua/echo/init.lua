local native = require("echo_native")

return {
	setup = function(opts)
		native.setup(opts)

		vim.api.nvim_create_augroup("echo_sound", {
			clear = true,
		})

		vim.api.nvim_create_autocmd("CursorMovedI", {
			group = "echo_sound",
			pattern = "*",
			callback = function()
				native.play_builtin("BUTTON_3")
			end,
		})
		vim.api.nvim_create_autocmd("BufWrite", {
			group = "echo_sound",
			pattern = "*",
			callback = function()
				local buf = vim.api.nvim_get_current_buf()
				local buf_modified = vim.api.nvim_buf_get_option(buf, "modified")
				if buf_modified then
					native.play_builtin("SUCCESS_1")
				end
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
