-- check if the working tree is on a tag matching "v.*.*.*"
local function get_git_tag()
	local describe_command = "git describe --tags --exact-match"
	local tag = vim.fn.system(describe_command) --execute(describe_command)
	if tag ~= nil then
		return tag:match("v[%d.]+")
	end
end

local function sysname()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "macos_aarch64",
		["Linux"] = "linux_x86_64",
		["Windows_NT"] = "windows_x86_64",
	}
	return mappings[_sysname]
end

local function libext()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "dylib", -- so ?? TODO: check as I still don't understand what should be used on macos
		["Linux"] = "so",
		["Windows_NT"] = "dll",
	}
	return mappings[_sysname]
end

-- Get the tag or use "canary" as the version
local version = get_git_tag() or "canary"
local os_name = sysname()

local function log(msg)
	vim.notify(msg, vim.log.levels.DEBUG, { title = "echo.nvim" })
end

-- shadows the builtin error()
local function error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "echo.nvim" }) -- Most prominent notifications
end

local function download_release(tag)
	local extension = libext()
	local lib_name = string.format("%s-echo_native.%s", os_name, extension)
	local url = string.format("https://github.com/melmass/echo.nvim/releases/download/%s/%s", tag, lib_name)

	local cmd = ""
	if vim.fn.executable("curl") == 1 then
		cmd = string.format("curl -fSL -o lua/%s %s", lib_name, url)
	elseif vim.fn.executable("wget") == 1 then
		cmd = string.format("wget --no-verbose --tries=3 --retry-connrefused -O lua/%s %s", lib_name, url)
	else
		error("build: Neither curl nor wget is available to download the binary.")
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
		error("build: Failed to download the binary.")
	end
end

log(string.format(" Downloading release for %s (os: %s)", version, os_name))
download_release(version)
