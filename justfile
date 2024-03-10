set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

BaseFile := os()

install_deps *param:
    just -f .just/{{ BaseFile }}.just install_deps {{ param }}

build *param:
    just -f .just/{{ BaseFile }}.just build {{ param }}

clean *param:
    just -f .just/{{ BaseFile }}.just clean {{ param }}

# after building move the relevant files for release to "./dist"
dist *param:
    just -f .just/{{ BaseFile }}.just dist {{ param }}

make: install_deps build clean dist
