use nvim_oxi::conversion::{Error as ConversionError, FromObject, ToObject};
use nvim_oxi::serde::{Deserializer, Serializer};
use nvim_oxi::{lua, Object};
use optfield::optfield;
use serde::{Deserialize, Serialize};

#[optfield(pub OptionsOpt, attrs)]
#[derive(Debug, Copy, Clone, Serialize, Deserialize)]
pub struct Options {
    pub amplify: f32,
    pub demo: bool,
}

impl Options {
    pub fn merge(&mut self, other: OptionsOpt) {
        // print!("Merging options, other: {other:?}");
        self.amplify = other.amplify.unwrap_or(self.amplify);
        self.demo = other.demo.unwrap_or(self.demo);
    }
}

impl Default for Options {
    fn default() -> Self {
        Self {
            amplify: 1.0,
            demo: false,
        }
    }
}

impl FromObject for Options {
    fn from_object(obj: Object) -> Result<Self, ConversionError> {
        // print!("called from_object on Options");
        Self::deserialize(Deserializer::new(obj)).map_err(Into::into)
    }
}

impl ToObject for Options {
    fn to_object(self) -> Result<Object, ConversionError> {
        // print!("called to_object on Options");
        self.serialize(Serializer::new()).map_err(Into::into)
    }
}
impl FromObject for OptionsOpt {
    fn from_object(obj: Object) -> Result<Self, ConversionError> {
        // print!("called from_object on OptionsOpt");
        Self::deserialize(Deserializer::new(obj)).map_err(Into::into)
    }
}

impl ToObject for OptionsOpt {
    fn to_object(self) -> Result<Object, ConversionError> {
        // print!("called to_object on OptionsOpt");
        self.serialize(Serializer::new()).map_err(Into::into)
    }
}

impl lua::Poppable for Options {
    unsafe fn pop(lstate: *mut lua::ffi::lua_State) -> Result<Self, lua::Error> {
        // print!("called pop on Options");
        let obj = Object::pop(lstate)?;
        Self::from_object(obj).map_err(lua::Error::pop_error_from_err::<Self, _>)
    }
}

impl lua::Pushable for Options {
    unsafe fn push(self, lstate: *mut lua::ffi::lua_State) -> Result<std::ffi::c_int, lua::Error> {
        // print!("called push on Options");
        self.to_object()
            .map_err(lua::Error::push_error_from_err::<Self, _>)?
            .push(lstate)
    }
}
impl lua::Poppable for OptionsOpt {
    unsafe fn pop(lstate: *mut lua::ffi::lua_State) -> Result<Self, lua::Error> {
        // print!("called pop on OptionsOpt");
        let obj = Object::pop(lstate)?;
        Self::from_object(obj).map_err(lua::Error::pop_error_from_err::<Self, _>)
    }
}

impl lua::Pushable for OptionsOpt {
    unsafe fn push(self, lstate: *mut lua::ffi::lua_State) -> Result<std::ffi::c_int, lua::Error> {
        // print!("called push on OptionsOpt");
        self.to_object()
            .map_err(lua::Error::push_error_from_err::<Self, _>)?
            .push(lstate)
    }
}

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
