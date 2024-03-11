# echo.nvim

*Experiment to try the rust bindings for neovim.*

<video src="https://github.com/melMass/echo.nvim/assets/7041726/162ceadb-b46b-4e8f-8fab-4fb03f0042f9"/>

Cross platform sound player for neovim (supports wav & mp3)  
Tested on **Native Windows** and **macOS** (should work fine under linux too)

## Limitations

- I doesn't work under [WSL](https://github.com/microsoft/WSL/issues/1631)

## Usage

You can quickly register events from the
[configuration](#configuration)'s `event` field.

You can also use the module in lua:

```lua
local echo = require("echo")

-- Play a sound from path
echo.play_sound("/path/to/file.mp3")

-- Play a sound from the builtins
echo.play_sound("builtin:SUCCESS_2")

-- List builtin sounds
print(vim.inspect(echo.list_builtin_sounds())
-- { "ALERT_1", "ALERT_2", "ALERT_3", "ALERT_4", "ALERT_5", "BUTTON_1", "BUTTON_2", "BUTTON_3", "BUTTON_4", "BUTTON_5", "BUTTON_6", "BUTTON_7", "BUTTON3", "CANCEL_1", "CANCEL_2", "COLLAPSE", "COMPLETE_1", "COMPLETE_2", "COMPLETE_3", "ERROR_1", "ERROR_2", "ERROR_3", "ERROR_4", "ERROR_5", "EXPAND", "NOTIFICATION_1", "NOTIFICATION_2", "NOTIFICATION_3", "NOTIFICATION_4", "NOTIFICATION_5", "NOTIFICATION_6", "NOTIFICATION_7", "NOTIFICATION_8", "NOTIFICATION_9", "SUCCESS_1", "SUCCESS_2", "SUCCESS_3", "TAB_1", "TAB_2", "TAB_3" }

```

## Features

- [x] Performant and cross platform SFX player (using rodio).
- [x] Rust <-> Lua Options
  - [x] Basic Override defaults from Lua
  - [ ] Live update (should just work but not exposed properly yet)
- [ ] Proper Lazy build step:
    - [ ] If possible add a `from_source` option, if not provided the build script should instead download it from github releases.


## Configuration

```lua
opts = {
  amplify = 0.5, -- the default level of amplification if not provided
                 -- (defaults to 1.0)
  demo = false,  -- install the demo events (the ones from the video demo)
  -- custom table of event -> sound mapping)
  events = {
    BufRead = { path = "builtin:EXPAND", amplify = 1.0 },
    BufWrite = { path = "builtin:SUCCESS_2", amplify = 1.0 },
    CursorMovedI = { path = "builtin:BUTTON_3", amplify = 0.45 },
    ExitPre = { path = "builtin:COMPLETE_3", amplify = 1.0 },
    InsertLeave = { path = "builtin:NOTIFICATION_5", amplify = 0.5 },
  }
}
```

- With **lazy**:

*As of version 0.0.1 this will not work since you need the built binary (found
in release), this will be the first thing to be solved for the next version.*

```lua
{
  'melmass/echo.nvim',
  opts = {
    demo = true,
  },
}
```

- Manually:

```lua
require("echo").setup(opts)
```


### Telescope Integration:

There is a telescope picker to preview the builtin sounds:

<video src="https://github.com/melMass/echo.nvim/assets/7041726/ec784fba-e64d-47fe-b578-da2556535070"/>

To register it run: 

```lua
require("telescope").register_extension("echo")
```

You can then call the command: `Telescope echo`
