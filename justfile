set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

BaseFile := os()

# install required sys dependencies if any.
install_deps *param:
    just -f .just/{{ BaseFile }}.just install_deps {{ param }}

# build the native module in target/release.
build *param:
    cargo build --release -- {{ param }}

build-nigthly *param:
    cargo build --release --no-default-features -F nightly -- {{ param }}

# remove the ./dist folder.
clean *param:
    just -f .just/{{ BaseFile }}.just clean {{ param }}

# turn dist into echo.nvim and zip it.
release name=("echo_nvim-" + BaseFile):
    just -f .just/{{ BaseFile }}.just release {{ name }}

# move the built release binary to the root of the repo
release_bin name=("echo_nvim-" + BaseFile):
    just -f .just/{{ BaseFile }}.just release_bin {{ name }}

# after building move the relevant files for release to "./dist"
dist *param:
    just -f .just/{{ BaseFile }}.just dist {{ param }}

# install deps, build, clean and make dist
make *param: install_deps build clean dist
