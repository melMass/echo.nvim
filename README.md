# echo.nvim

*Experiment to try the rust bindings for neovim.*

https://github.com/melMass/echo.nvim/assets/7041726/162ceadb-b46b-4e8f-8fab-4fb03f0042f9

 

Cross platform sound player for neovim (supports wav & mp3)  
Tested on Native Windows and macOS

## Limitations

- Doesn't work under [WSL](https://github.com/microsoft/WSL/issues/2187) (I don't use it)

## Features

- [x] Performant and cross platform SFX player (using rodio).
- [ ] Rust <-> Lua Options
  - [x] Basic Override defaults from Lua
  - [ ] Live update (should just work but not exposed properly yet)
- [ ] Proper Lazy build step:
    - [ ] If possible add a `from_source` option, if not provided the build script should instead download it from github releases.
