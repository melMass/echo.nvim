local M = {}

local function log(msg)
	vim.notify(msg, vim.log.levels.DEBUG, { title = "echo.nvim" })
end

local function log_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "echo.nvim" })
end

M.get_git_tag = function()
	local describe_command = "git describe --tags --exact-match"
	local tag = vim.fn.system(describe_command) --execute(describe_command)
	if tag ~= nil then
		return tag:match("v[%d.]+")
	end
end

M.sysname = function()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "macos_aarch64",
		["Linux"] = "linux_x86_64",
		["Windows_NT"] = "windows_x86_64",
	}
	return mappings[_sysname]
end

M.libext = function()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "so",
		["Linux"] = "so",
		["Windows_NT"] = "dll",
	}
	return mappings[_sysname]
end

M.download_release = function(tag)
	local extension = M.libext()
	local os_name = M.sysname()

	local dest_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

	vim.notify("build: Downloading binary to " .. dest_dir, vim.log.levels.INFO, { title = "echo.nvim" })

	local lib_name = string.format("%s-echo_native.%s", os_name, extension)
	local url = string.format("https://github.com/melmass/echo.nvim/releases/download/%s/%s", tag, lib_name)

	local cmd = ""
	if vim.fn.executable("curl") == 1 then
		cmd = string.format("curl -fSL -o %s/echo_native.%s %s", dest_dir, extension, url)
	elseif vim.fn.executable("wget") == 1 then
		cmd = string.format(
			"wget --no-verbose --tries=3 --retry-connrefused -O %s/echo_native.%s %s",
			dest_dir,
			extension,
			url
		)
	else
		log_error("build: Neither curl nor wget is available to download the binary.")
		return
	end

	log("Executing " .. cmd)
	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("build:  Success", vim.log.levels.INFO, { title = "echo.nvim" })
	else
		log("build:  Error status:")
		if vim.fn.filereadable("lua/" .. lib_name) == 1 then
			os.remove("lua/" .. lib_name)
		end
		log_error("build: Failed to download the binary.")
	end
end

M.download_binary = function()
	local version = M.get_git_tag() or "canary"
	local os_name = M.sysname()
	log(string.format(" Downloading release for %s (os: %s)", version, os_name))
	M.download_release(version)
end

return M
