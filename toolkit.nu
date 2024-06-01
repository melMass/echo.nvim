export-env {
  # let os = $nu.os-info
  # $env.opts = {
  #   name: echo,
  #   windows: ($os.name == windows),
  #   linux: ($os.name == linux),
  #   darwin: ($os.name == macos),
  #   prefix: $"($os.name)_($os.arch)"
  # }
  $env.HERE = ("." | path expand)
}

export def "install_deps" [] {

  print $"(ansi yellow)Installing dependencies for ($nu.os-info.name)(ansi reset)"
  if $env.opts.darwin {
    brew install coreutils
  } else if $env.opts.linux {
    sudo apt update
    sudo apt install -y libasound2-dev
  } else {
    print "No extra deps on windows"
  }
}

export def "clean" [] {
  cd $env.HERE
  ["dist", "echo.nvim"] | each { |f|
    if ($f | path exists) {
      rm -r $f
    }
  }
}

export def "zip_release" [name:string] {
  cd $env.HERE
  let name = $"echo.nvim-($env.opts.prefix)-($env.opts.name)-($name).zip"

  if $env.opts.windows {
    7z a -mfb=258 -tzip $name "echo.nvim"  
  } else  {
    ^zip -r -9 -y -m $name "echo.nvim"
  }

  return $name
}

export def --env "release" [name:string, --nightly] {
  cd $env.HERE

  $env.opts.name = "echo"
  install_deps

  if $nightly {
    cargo build --release --no-default-features -F nightly

  } else {
      cargo build --release
  }
  clean

  # NOTE: make a separate directory 
  mkdir echo.nvim 
  cp -r lua echo.nvim
  cp README.md echo.nvim

  # NOTE: copy the binary
  let os = $nu.os-info.name
  let ext = if $os == "windows" {"dll"} else if $os == "macos" { "dylib" } else {"so"}

  let bin_prefix = if $env.opts.windows { "" } else {"lib"}
  let build_bin = $"($env.opts.name)_native.($ext)"
  let build = $"target/release/($bin_prefix)($build_bin)"
  let target_bin = $"($env.opts.prefix)-($env.opts.name)_native.($ext)"

  cp $build $"echo.nvim/lua/($build_bin)"
  cp $build $target_bin

  # let zip_name = zip_release $name
  let zip_name = zip-release $name echo.nvim
  { name: $target_bin, zip_name: $zip_name} | to-github --output

  return {bin:$target_bin, zip:$zip_name}
}
