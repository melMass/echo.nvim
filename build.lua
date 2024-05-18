local function execute(command)
	local handle = io.popen(command)
	if handle ~= nil then
		local result = handle:read("*a")
		if result ~= nil then
			handle:close()
			return result
		end
	end
end

-- check if the working tree is on a tag matching "v.*.*.*"
local function get_git_tag()
	local describe_command = "git describe --tags --exact-match"
	local tag = vim.fn.system(describe_command) --execute(describe_command)
	if tag ~= nil then
		return tag:match("v%d+%.%d+%.%d+")
	end
end

local function sysname()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "darwin_arm64",
		["Linux"] = "linux_x64",
		["Windows_NT"] = "win32_x64",
	}
	return mappings[_sysname]
end

local function libname()
	local _sysname = vim.loop.os_uname().sysname
	local mappings = {
		["Darwin"] = "echo_native.so",
		["Linux"] = "echo_native.so",
		["Windows_NT"] = "echo_native.dll",
	}
	return mappings[_sysname]
end

-- Get the tag or use "canary" as the version
local version = get_git_tag() or "canary"
local os_name = sysname()

local function download_release_zip(tag)
	local zip_name = string.format("echo.nvim-%s-%s.zip", os_name, tag)

	local url = string.format("https://github.com/melmass/echo.nvim/releases/download/%s/%s", tag, zip_name)

	local cmd = ""
	if vim.fn.executable("curl") == 1 then
		cmd = string.format("curl -L -o %s %s", zip_name, url)
	elseif vim.fn.executable("wget") == 1 then
		cmd = string.format("wget -O %s %s", zip_name, url)
	else
		error("Neither curl nor wget is available to download the binary.")
	end
	vim.fn.system(cmd)
end

local function download_release(tag)
	local lib_name = libname()
	local dll_name = string.format("%s-%s", os_name, libname())
	local url = string.format("https://github.com/melmass/echo.nvim/releases/download/%s/%s", tag, dll_name)

	local cmd = ""
	if vim.fn.executable("curl") == 1 then
		cmd = string.format("curl -L -o lua/%s %s", lib_name, url)
	elseif vim.fn.executable("wget") == 1 then
		cmd = string.format("wget --no-verbose --tries=3 --retry-connrefused -O lua/%s %s", lib_name, url)
	else
		error(" Neither curl nor wget is available to download the binary.")
	end

	print("Executing " .. cmd)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		print(" Success")
	else
		print(" Error status:", vim.v.shell_error)
		os.remove(lib_name)
		error("Failed to download the binary.")
	end
end

print(string.format(" Downloading release for %s (os: %s)", version, os_name))
download_release(version)
