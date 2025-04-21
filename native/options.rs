use nvim_oxi::conversion::{Error as ConversionError, FromObject, ToObject};
use nvim_oxi::serde::{Deserializer, Serializer};
use nvim_oxi::{lua, Object};
use optfield::optfield;
use serde::{Deserialize, Serialize};

use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Event {
    pub path: String,
    pub amplify: Option<f64>,
}

#[optfield(pub OptionsOpt, attrs)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Options {
    pub amplify: f64,
    pub demo: bool,
    pub events: HashMap<String, Event>,
}

impl Options {
    /// crude option merging, might use typetag and whatnot if
    /// options become more complex
    pub fn merge(&mut self, other: OptionsOpt) {
        // nvim_oxi::print!("Merging options, other: {other:?}");
        self.amplify = other.amplify.unwrap_or(self.amplify);
        self.demo = other.demo.unwrap_or(self.demo);
        if let Some(events) = other.events {
            for (key, event) in events {
                self.events
                    .entry(key)
                    .and_modify(|existing| {
                        if let Some(a) = event.amplify {
                            existing.amplify = Some(a);
                        }
                        if !event.path.is_empty() {
                            existing.path = event.path.clone();
                        }
                    })
                    .or_insert(event);
            }
        }
    }
}

impl Default for Options {
    fn default() -> Self {
        Self {
            amplify: 1.0,
            demo: false,
            events: HashMap::new(),
        }
    }
}
macro_rules! impl_nvim_conversion {
    ($t:ty) => {
        impl FromObject for $t {
            fn from_object(obj: Object) -> Result<Self, ConversionError> {
                Self::deserialize(Deserializer::new(obj)).map_err(Into::into)
            }
        }

        impl ToObject for $t {
            fn to_object(self) -> Result<Object, ConversionError> {
                self.serialize(Serializer::new()).map_err(Into::into)
            }
        }

        impl lua::Poppable for $t {
            unsafe fn pop(lstate: *mut lua::ffi::State) -> Result<Self, lua::Error> {
                let obj = Object::pop(lstate)?;
                Self::from_object(obj).map_err(lua::Error::pop_error_from_err::<Self, _>)
            }
        }

        impl lua::Pushable for $t {
            unsafe fn push(
                self,
                lstate: *mut lua::ffi::State,
            ) -> Result<std::ffi::c_int, lua::Error> {
                self.to_object()
                    .map_err(lua::Error::push_error_from_err::<Self, _>)?
                    .push(lstate)
            }
        }
    };
}

impl_nvim_conversion!(Options);
impl_nvim_conversion!(OptionsOpt);

// merging
// fn merge_value(a: &mut Value, b: &Value) {
//     match (a, b) {
//         (Value::Object(ref mut a), &Value::Object(ref b)) => {
//             for (k, v) in b {
//                 merge_value(a.entry(k).or_insert(Value::Null), v);
//             }
//         }
//         (Value::Array(ref mut a), &Value::Array(ref b)) => {
//             a.extend(b.clone());
//         }
//         (Value::Array(ref mut a), &Value::Object(ref b)) => {
//             a.extend([Value::Object(b.clone())]);
//         }
//         (_, Value::Null) => {} // do nothing
//         (a, b) => {
//             *a = b.clone();
//         }
//     }
// }
// fn to_value<T: serde::ser::Serialize>(value: &T) -> Result<serde_json::Value, serde_json::Error> {
//     serde_json::to_value(value)
// }
//
// fn from_value<T: serde::ser::Serialize + serde::de::DeserializeOwned>(
//     value: serde_json::Value,
// ) -> Result<T, serde_json::Error> {
//     serde_json::from_value(value)
// }
//
// pub fn deep_merge<T: serde::ser::Serialize + serde::de::DeserializeOwned>(
//     base: &T,
//     overrides: &T,
// ) -> Result<T, serde_json::Error> {
//     let mut left = to_value(base)?;
//     let right = to_value(overrides)?;
//     merge_value(&mut left, &right);
//     from_value(left)
// }
