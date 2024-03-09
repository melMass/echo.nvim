use crate::error::Error;
use rodio::{source::Source, Decoder, OutputStream};
use std::io::Cursor;
use std::sync::mpsc::{self, Sender};
use std::thread;

pub struct SoundPlayer {
    sender: Sender<(Vec<u8>, f32)>,
}

impl SoundPlayer {
    pub fn new() -> Result<Self, Error> {
        let (tx, rx) = mpsc::channel::<(Vec<u8>, f32)>();
        thread::spawn(move || {
            let (_stream, stream_handle) = match OutputStream::try_default() {
                Ok(result) => result,
                Err(e) => {
                    eprintln!("Output stream not found: {:?}", e);
                    return;
                }
            };

            for (bytes, amplify) in rx {
                let cursor = Cursor::new(bytes);
                match Decoder::new(cursor) {
                    Ok(source) => {
                        let source = source.amplify(amplify);
                        if let Err(e) = stream_handle.play_raw(source.convert_samples()) {
                            eprintln!("Failed to play sound: {:?}", e);
                        }
                    }
                    Err(e) => {
                        eprintln!("Failed to decode sound file: {:?}", e);
                    }
                }
            }
        });

        Ok(SoundPlayer { sender: tx })
    }

    pub fn play_sound(&self, bytes: Vec<u8>, amplify: f32) {
        let sender = self.sender.send((bytes, amplify));
        if sender.is_err() {
            eprintln!("An error occurred: {:?}", sender.unwrap_err());
        }
    }
}
