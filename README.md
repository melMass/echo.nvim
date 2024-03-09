# echo.nvim

*Experiment to try the rust bindings for neovim.*

Cross platform sound player for neovim (supports wav & mp3)  
Tested on Native Windows and macOS


## Features

- [x] Performant and cross platform SFX player (using rodio).
- [ ] Rust <-> Lua Options
  - [x] Basic Override defaults from Lua
  - [ ] Live update (should just work but not exposed properly yet)
- [ ] Proper Lazy build step:
    - [ ] If possible add a `from_source` option, if not provided the build script should instead download it from github releases.
