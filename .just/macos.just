import 'common.just'

install_deps *param:
    #!/bin/bash
    brew install coreutils

clean:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")

    if [ -d "$PROJECT_DIR/dist" ]; then
      rm -rf "$PROJECT_DIR/dist"
    fi

release name:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")

    cd "$PROJECT_DIR"
    mv "dist" "echo.nvim"
    zip -r -9 -y -m "{{ name }}.zip" "echo.nvim"

release_bin name:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")

    cd "$PROJECT_DIR"
    cp "target/release/lib{{ PluginName }}_native.dylib" "{{ name }}"

dist *param:
    #!/bin/bash
    set -e
    PROJECT_DIR=$(realpath "{{ ProjectDir }}")

    cd "$PROJECT_DIR"
    mkdir -p "dist"

    cp -r "lua" "dist"
    cp README.md "dist/README.md"

    cp "target/release/lib{{ PluginName }}_native.dylib" "dist/lua/{{ PluginName }}_native.so"
