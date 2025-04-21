use nvim_oxi::api;
use thiserror::Error as ThisError;

#[derive(Clone, Debug, ThisError, Eq, PartialEq)]
pub enum Error {
    #[error("Failed to initialize: `{0}`")]
    Initialization(String),

    #[error("Could not find sound `{0}`")]
    SoundNotFound(String),

    #[error("Runtime: `{0}`")]
    Runtime(String),
}

impl From<Error> for api::Error {
    fn from(value: Error) -> Self {
        api::Error::Other(value.to_string())
    }
}

impl From<Error> for nvim_oxi::Error {
    fn from(value: Error) -> Self {
        nvim_oxi::Error::Api(value.into())
    }
}

