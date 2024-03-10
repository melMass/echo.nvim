import 'common.just'

install_deps *param:
    #!/bin/bash
    echo "No deps needed on macos"

build *param:
    cargo build --release -- {{ param }}

clean:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")
    rm -rf "$PROJECT_DIR/dist"

dist *param:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")

    cd "$PROJECT_DIR"
    mkdir -p "dist"

    cp -r "lua" "dist"
    cp README.md "dist/README.md"

    cp "target/release/lib{{ PluginName }}_native.dylib" "dist/lua/{{ PluginName }}_native.dylib"
