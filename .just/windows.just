import 'common.just'

install_deps *param:
    Write-Output "No extra deps on windows"

build *param:
    cargo build --release -- {{ param }}

clean:
    #!powershell
    $ErrorActionPreference = 'Stop'
    $ProjectDir = resolve-path "{{ ProjectDir }}"

    if (Test-Path "$ProjectDir\dist") {
      Remove-Item -Recurse -Force "$ProjectDir\dist"
    }

release name:
    #!powershell
    $ErrorActionPreference = 'Stop'
    $ProjectDir = resolve-path "{{ ProjectDir }}"

    Set-Location -Path "$ProjectDir" 
    Move-Item "dist" "echo.nvim"
    7z a -mfb=258 -tzip "{{ name }}.zip" "echo.nvim"  

release_bin name:
    #!powershell
    $ErrorActionPreference = 'Stop'
    $ProjectDir = resolve-path "{{ ProjectDir }}"

    cd "$ProjectDir"
    Copy-Item "target\release\{{ PluginName }}_native.dll" "{{ name }}"

dist *param:
    #!powershell
    $ErrorActionPreference = 'Stop'
    $ProjectDir = resolve-path "{{ ProjectDir }}"

    cd "$ProjectDir"
    New-Item -Path "dist" -ItemType Directory

    Copy-Item -Recurse "lua" "dist"
    Copy-Item README.md "dist\README.md"

    Copy-Item "target\release\{{ PluginName }}_native.dll" "dist\lua\{{ PluginName }}_native.dll"
