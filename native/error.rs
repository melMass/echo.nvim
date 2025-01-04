use nvim_oxi::api;
use thiserror::Error as ThisError;

#[derive(Clone, Debug, ThisError, Eq, PartialEq)]
pub enum Error {
    #[error("Failed to initialize: `{0}`")]
    Initialization(String),

    #[error("Failed to register: `{0}`")]
    Registration(String),

    #[error("Could not find sound `{0}`")]
    SoundNotFound(String),

    #[error("Runtime: `{0}`")]
    Runtime(String),
}

impl Into<api::Error> for Error {
    fn into(self) -> api::Error {
        api::Error::Other(self.to_string())
    }
}

impl Into<nvim_oxi::Error> for Error {
    fn into(self) -> nvim_oxi::Error {
        nvim_oxi::Error::Api(self.into())
    }
}

