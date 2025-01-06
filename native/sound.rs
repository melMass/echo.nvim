use crate::builtin_sounds;
use crate::error::Error;
use rodio::{source::Source, Decoder, OutputStream};
use std::io::Cursor;
// use std::path::PathBuf;
use std::sync::mpsc::{self, Sender};
use std::sync::Arc;
use std::thread;
use tokio::runtime::Runtime;
use tokio::sync::Semaphore;

pub struct SoundPlayer {
    sender: Sender<(Vec<u8>, f32)>,
}

impl SoundPlayer {
    pub fn new(max_concurrent_sounds: usize) -> Result<Self, Error> {
        let (tx, rx) = mpsc::channel::<(Vec<u8>, f32)>();
        let semaphore = Semaphore::new(max_concurrent_sounds);
        thread::spawn(move || {
            let rt = Runtime::new().unwrap();
            let (_stream, stream_handle) = OutputStream::try_default().unwrap();

            for (bytes, amplify) in rx.iter() {
                rt.block_on(async {
                    let _permit = semaphore
                        .acquire()
                        .await
                        .expect("Failed to acquire semaphore permit");

                    let cursor = Cursor::new(bytes);
                    if let Ok(source) = Decoder::new(cursor) {
                        let source = source.amplify(amplify);
                        stream_handle
                            .play_raw(source.convert_samples())
                            .expect("Failed to play sound");
                    } else {
                        eprintln!("Failed to decode sound");
                    }
                });
            }
        });

        Ok(SoundPlayer { sender: tx })
    }
    pub fn play_from_path(&self, path: String, amplify: f64) -> Result<(), Error> {
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
        self.play_from_bytes(bytes, amplify)
    }
    pub fn play_from_bytes(&self, bytes: Vec<u8>, amplify: f64) -> Result<(), Error> {
        Ok(self
            .sender
            .send((bytes, amplify as f32))
            .map_err(|e| Error::Runtime(e.to_string()))?)
    }
}
