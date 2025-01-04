export-env {
  # let os = $nu.os-info
  # $env.opts = {
  #   name: echo,
  #   windows: ($os.name == windows),
  #   linux: ($os.name == linux),
  #   darwin: ($os.name == macos),
  #   prefix: $"($os.name)_($os.arch)"
  # }
  $env.os = $nu.os-info.name
  $env.HERE = ("." | path expand)
}

export def "install_deps" [] {
  print $"(ansi yellow)Installing dependencies for ($nu.os-info.name)(ansi reset)"
  if $env.os == "macos" {
    brew install coreutils
  } else if $env.os == "linux" {
    sudo apt update
    sudo apt install -y libasound2-dev
  } else {
    print "No extra deps on windows"
  }
}

export def "clean" [] {
  cd $env.HERE
  ["dist" "echo.nvim"] | each {|f|
    if ($f | path exists) {
      rm -r $f
    }
  }
}

export def "zip_release" [name: string] {
  cd $env.HERE
  let name = $"echo.nvim-($env.opts.prefix)-($env.opts.name)-($name).zip"

  if $env.os == windows {
    7z a -mfb=258 -tzip $name "echo.nvim"
  } else {
    ^zip -r -9 -y -m $name "echo.nvim"
  }

  return $name
}

export def --env "release" [name: string = "canary", --ci, --nightly] {
  cd $env.HERE

  $env.opts.name = "echo"
  install_deps

  if $nightly {
    cargo build --release --no-default-features -F nightly
  } else {
    cargo build --release
  }

  let src_ext = if $env.os == "windows" { "dll" } else if $env.os == "macos" { "dylib" } else { "so" }

  let ext = if $env.os == "windows" { "dll" } else if $env.os == "macos" { "so" } else { "so" }

  let bin_prefix = if $env.os == "windows" { "" } else { "lib" }
  let bin_name = $"($env.opts.name)_native"

  let build = $"target/release/($bin_prefix)($bin_name).($src_ext)"
  let install = $"lua/($bin_name).($ext)"

  cp $build $install

  if ($ci) {
    clean
    let target_bin = $"($env.opts.prefix)-($env.opts.name)_native.($ext)"

    mkdir echo.nvim
    cp -r lua echo.nvim
    cp README.md echo.nvim
    cp $build $target_bin

    # let zip_name = zip_release $name
    let zip_name = zip-release $name echo.nvim
    {name: $target_bin zip_name: $zip_name} | to-github --output
    return {bin: $target_bin zip: $zip_name}
  }
}
