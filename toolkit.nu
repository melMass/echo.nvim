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
    let zip_name = zip-release echo.nvim $name
    let tlk = {bin: $target_bin zip: $zip_name}
    let release_files = [$tlk.bin $tlk.zip]

    let existing = (gh release list --json name | from json | get name)

    if $env.RELEASE_NAME not-in $existing {
      if $env.RELEASE_NAME == "canary" {
        let created = (gh release create $env.RELEASE_NAME ...$release_files --prerelease --latest=false | complete)
        if $created.exit_code > 0 {
          gh release upload $env.RELEASE_NAME ...$release_files --clobber
        }
      } else {
        gh release create $env.RELEASE_NAME ...$release_files
      }
    } else {
      gh release upload $env.RELEASE_NAME ...$release_files --clobber
    }
    return $tlk
  }
}
