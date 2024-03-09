mod error;
mod options;
mod sound;
use std::sync::{Arc, Mutex};

// use nvim_oxi::api::{self, opts::*, types::*, Window};
// use nvim_oxi::lua::{Poppable, Pushable};
use nvim_oxi::{Dictionary, Function, Result};

use crate::error::Error;
use options::{Options, OptionsOpt};
use sound::SoundPlayer;

// TODO:
// - add a telescope picker with sound preview.
// - add a way to use random sounds / amplitudes.

mod builtin_sounds {
    include!(concat!(env!("OUT_DIR"), "/sounds.rs"));
}

#[nvim_oxi::plugin]
fn echo_native() -> Result<Dictionary> {
    let player = match SoundPlayer::new() {
        Ok(p) => Arc::new(Mutex::new(p)),
        Err(e) => {
            return Err(
                Error::Initialization(format!("Failed to initialize SoundPlayer: {:?}", e)).into(),
            )
        }
    };

    let mut module = Dictionary::new();
    let options = Arc::new(Mutex::new(Options::default()));

    let play_sound = Function::from_fn({
        let player = Arc::clone(&player);
        let options_clone = Arc::clone(&options);
        move |(path, amplify): (String, Option<f32>)| {
            let options = options_clone.lock().unwrap();
            let amplitude = amplify.unwrap_or(options.amplify);
            let bytes = std::fs::read(&path).unwrap_or_else(|err| {
                eprintln!("Failed to read file {}: {:?}", &path, err);
                Vec::new()
            });
            let player = player.lock().unwrap();
            player.play_sound(bytes, amplitude);
            Ok::<(), Error>(())
        }
    });
    module.insert("play_sound", play_sound);

    // Setup exposed for lazy.nvim etc..
    let setup = Function::from_fn({
        let options_clone = Arc::clone(&options);
        move |opts: OptionsOpt| {
            let mut options = options_clone.lock().unwrap();
            options.merge(opts);

            // print!("Options are now: {options:?}");
            Ok::<(), Error>(())
        }
    });
    module.insert("setup", setup);

    // Get runtime options
    let get_options = Function::from_fn({
        let options_clone = Arc::clone(&options);
        move |()| {
            let options = options_clone.lock().unwrap();
            // print!("Asking for options: {options:?}");
            Ok::<Options, nvim_oxi::Error>(options.clone())
        }
    });
    module.insert("options", get_options);

    // Play a builtin file
    let play_builtin = Function::from_fn({
        let player = Arc::clone(&player);
        let options_clone = Arc::clone(&options);
        move |sound_name: String| {
            let sound = builtin_sounds::SOUND_NAMES
                .iter()
                .find(|&&n| n == sound_name);
            match sound {
                Some(snd) => {
                    let options = options_clone
                        .lock()
                        .unwrap_or_else(|poison| poison.into_inner());

                    let data = builtin_sounds::get_sound_from_string(snd).unwrap().to_vec();
                    let player = player.lock().unwrap();
                    player.play_sound(data, options.amplify);
                }
                None => {
                    return Err(Error::SoundNotFound(format!(
                        "{}, available sounds: {:?}",
                        sound_name,
                        builtin_sounds::SOUND_NAMES
                    )));
                }
            };

            Ok::<(), Error>(())
        }
    });
    module.insert("play_builtin", play_builtin);

    // List builtin sounds
    let list_builtin = Function::from_fn(move |()| {
        let keys: Vec<String> = builtin_sounds::SOUND_NAMES
            .iter()
            .map(|x| x.to_string())
            .collect();
        Ok::<Vec<String>, Error>(keys)
    });
    module.insert("list_builtin_sounds", list_builtin);
    Ok(module)
}
