use std::fs;
use std::path::{Path, PathBuf};

fn main() {
    // NOTE: Collecting the "builtin" sounds at build time, this is exposed as a module
    // where all sounds are const array of bytes and a SOUND_NAMES array containing the full list
    // of names
    let sound_dir = Path::new("assets").join("sounds_mp3");
    let mut sound_includes = Vec::new();
    let mut sound_names = Vec::new();
    let man_dir = Path::new(env!("CARGO_MANIFEST_DIR"));

    // gather files and data
    for entry in fs::read_dir(sound_dir).unwrap() {
        let entry = entry.unwrap();
        let file_path = entry.path();

        if let Some(extension) = file_path.extension() {
            if let Some(ext_str) = extension.to_str() {
                if ext_str.eq_ignore_ascii_case("wav") || ext_str.eq_ignore_ascii_case("mp3") {
                    let stem = file_path
                        .file_stem()
                        .and_then(|x| Some(x.to_string_lossy().to_string()))
                        .unwrap_or_else(|| String::from("unknown"))
                        .replace(".", "_")
                        .replace(" ", "_")
                        .to_uppercase();

                    let include_macro = format!(
                        "pub const {}: &[u8] = include_bytes!(\"{}\");",
                        stem,
                        man_dir.join(file_path).to_string_lossy().replace("\\", "/")
                    );
                    sound_names.push(stem.clone());
                    sound_includes.push(include_macro);
                }
            }
        }
    }

    // a simple getter helper
    let from_string_fn = format!(
        r#"
        pub fn get_sound_from_string(name: &str) -> Option<&'static [u8]> {{
            match name {{
                {}
                _ => None,
            }}
        }}
        "#,
        sound_names
            .iter()
            .map(|name| { format!(r#""{}" => Some(&{}),"#, name, name) })
            .collect::<Vec<_>>()
            .join("\n")
    );
    let quoted_sound_names: Vec<String> =
        sound_names.iter().map(|n| format!("\"{}\"", n)).collect();

    let source_code = format!(
        "{}\n\n{}\n\n{}\n\npub const SOUND_NAMES: &[&str] = &[{}];",
        "// This file is generated by build.rs. Do not edit.",
        sound_includes.join("\n"),
        from_string_fn,
        quoted_sound_names.join(", ")
    );

    let out_dir = PathBuf::from(std::env::var("OUT_DIR").unwrap());
    fs::write(out_dir.join("sounds.rs"), source_code).unwrap();
}
