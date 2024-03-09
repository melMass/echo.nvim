set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

BaseFile := os()

build *param:
    just -f .just/{{ BaseFile }}.just build {{ param }}

clean *param:
    just -f .just/{{ BaseFile }}.just clean {{ param }}

# after building move the relevant files for release to "./dist"
dist *param:
    just -f .just/{{ BaseFile }}.just dist {{ param }}

make: build clean dist
