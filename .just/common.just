set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

PluginName := "echo"
PathSep := if os() == "windows" { ";" } else { ":" }
ProjectDir := if path_exists(justfile_directory() / ".." / "Cargo.toml") == "true" { justfile_directory() / "../" } else { justfile_directory() }
