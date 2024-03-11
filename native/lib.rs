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
// - add a way to use random sounds / amplitudes.
// - add some logging to file / a verbose mode.

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

    let _play_sound = {
        let player = Arc::clone(&player);
        let options_clone = Arc::clone(&options);

        move |(path, amplify): (String, Option<f64>)| {
            let options = options_clone.lock().unwrap();
            let amplitude = amplify.unwrap_or(options.amplify);
            let bytes = if let Some(rest) = path.strip_prefix("builtin:") {
                let name = rest.trim();
                let sound = builtin_sounds::SOUND_NAMES.iter().find(|&&n| n == name);
                match sound {
                    Some(snd) => {
                        let data = builtin_sounds::get_sound_from_string(snd).unwrap().to_vec();
                        data
                    }
                    None => {
                        return Err(Error::SoundNotFound(format!(
                            "{}, available sounds: {:?}",
                            name,
                            builtin_sounds::SOUND_NAMES
                        )));
                    }
                }
            } else {
                std::fs::read(&path).unwrap_or_else(|err| {
                    eprintln!("Failed to read file {}: {:?}", &path, err);
                    Vec::new()
                })
            };

            let player = player.lock().unwrap();
            player.play_sound(bytes, amplitude);
            Ok::<(), Error>(())
        }
    };

    // Setup exposed for lazy.nvim etc..
    let setup = Function::from_fn({
        let options_clone = Arc::clone(&options);
        move |opts: OptionsOpt| {
            let mut options = options_clone.lock().unwrap();
            options.merge(opts);
            // print!("Options are now: {options:?}");
            Ok::<Options, Error>(options.clone())
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

    let play_sound = Function::from_fn(_play_sound);
    module.insert("play_sound", play_sound);

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
