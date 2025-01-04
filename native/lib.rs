// #[cfg(all(feature = "nightly", feature = "stable"))]
// compile_error!("feature \"stable\" and feature \"nightly\" cannot be enabled at the same time");

mod error;
mod options;
mod sound;
use std::sync::{Arc, Mutex};

// use nvim_oxi::print;
use nvim_oxi::{Dictionary, Function, Result};
use nvim_oxi_api::{
    opts::CreateCommandOpts,
    types::{CommandArgs, CommandNArgs},
};

use crate::error::Error;
use options::{Options, OptionsOpt};
use sound::SoundPlayer;

// TODO:
// - add a way to use random sounds / amplitudes.
// - add some logging to file / a verbose mode.

mod builtin_sounds {
    include!(concat!(env!("OUT_DIR"), "/sounds.rs"));
}

#[nvim_oxi::plugin]
fn echo_native() -> Result<Dictionary> {
    let player = match SoundPlayer::new(1) {
        Ok(p) => Arc::new(Mutex::new(p)),
        Err(e) => {
            return Err(
                Error::Initialization(format!("Failed to initialize SoundPlayer: {:?}", e)).into(),
            )
        }
    };

    let mut module = Dictionary::new();
    let options = Arc::new(Mutex::new(Options::default()));

    // Setup exposed for lazy.nvim etc..
    let setup: Function<OptionsOpt, Options> = Function::from_fn({
        let options_clone = Arc::clone(&options);
        move |opts: OptionsOpt| {
            let mut options = options_clone.lock().unwrap();
            options.merge(opts);
            // print!("Options are now: {options:?}");
            Ok::<Options, Error>(options.clone())
        }
    });

    // Get runtime options
    let get_options: Function<(), Options> = Function::from_fn({
        let options_clone = Arc::clone(&options);
        move |()| {
            let options = options_clone.lock().unwrap();
            // print!("Asking for options: {options:?}");
            Ok::<Options, nvim_oxi::Error>(options.clone())
        }
    });

    let play_sound: Function<(std::string::String, Option<f64>), ()> = Function::from_fn({
        let player = Arc::clone(&player);
        let options_clone = Arc::clone(&options);

        move |(path, amplify): (String, Option<f64>)| {
            let options = options_clone.lock().unwrap();
            let amplitude = amplify.unwrap_or(options.amplify);
            let player = player.lock().unwrap();
            player.play_from_path(path, amplitude)
        }
    });
    let opts = CreateCommandOpts::builder()
        .bang(true)
        .desc("play audio using echo.nvim")
        .nargs(CommandNArgs::ZeroOrOne)
        .build();

    let play_cmd = {
        let player = Arc::clone(&player);
        move |args: CommandArgs| {
            let sound = args.args.unwrap_or("builtin:NOTIFICATION_7".to_owned());
            let player = player.lock().unwrap();
            player.play_from_path(sound, 1.0)
            // let bang = if args.bang { "!" } else { "" };
        }
    };

    // List builtin sounds
    let list_builtin: Function<(), Vec<std::string::String>> = Function::from_fn(move |()| {
        let keys: Vec<String> = builtin_sounds::SOUND_NAMES
            .iter()
            .map(|x| x.to_string())
            .collect();
        Ok::<Vec<String>, Error>(keys)
    });

    // register
    module.insert("setup", setup);
    module.insert("options", get_options);
    module.insert("play_sound", play_sound);
    module.insert("list_builtin_sounds", list_builtin);

    // custom command
    nvim_oxi::api::create_user_command("PlaySound", play_cmd, &opts)?;

    Ok(module)
}
