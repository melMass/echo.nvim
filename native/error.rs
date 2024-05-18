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
impl From<Error> for nvim_oxi::Error {
    fn from(val: Error) -> Self {
        nvim_oxi::Error::from(Into::<api::Error>::into(val))
    }
}
