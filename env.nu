# NOTE: This overlay is only used for testing the overseer extension of echo.
# I use it with this custom overseer provider: https://gist.github.com/melMass/1847645763b7bc55859fa8a26a500e8f

export-env {
  $env.NAME = "moto"
}

export def "success" [] {
  sleep 500ms
  print $env.NAME
}

export def "errorout" [] {
  sleep 500ms
  error make {msg: "NO!", }
}
