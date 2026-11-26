#!/usr/bin/env bash
# Fast development loop for the shell.
#
# Run it inside the flake dev shell, which provides qs, clang and the Qt deps:
#
#     nix develop -c scripts/dev.sh
#
# It builds the C++ plugin incrementally into ./build (the first run is the
# slow one; later runs only rebuild what changed), then stops the installed
# caelestia systemd service and runs the shell straight from the working tree.
# The dev copy of shell.qml keeps settings.watchFiles enabled, so every QML
# save reloads the shell in about a second without compiling anything.
# The installed service is restored when this script exits.

set -euo pipefail

cd "$(dirname "$0")/.."

# Lets ccache cache compilations that use CMake's precompiled headers.
export CCACHE_SLOPPINESS="${CCACHE_SLOPPINESS:+$CCACHE_SLOPPINESS,}pch_defines,time_macros"

if ! command -v qs >/dev/null; then
    echo "error: qs not found — run inside the dev shell: nix develop -c scripts/dev.sh" >&2
    exit 1
fi

# Incremental build of the C++ plugin and compiled QML modules.
if ! cmake --build build --target help >/dev/null 2>&1; then
    args=(-DCMAKE_CXX_COMPILER=clang++)
    if command -v ccache >/dev/null; then
        args+=(-DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
    fi
    args+=(
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DDISTRIBUTOR=dev
        -DCAELESTIA_TEST_TRS=ON
    )
    cmake -B build -G Ninja "${args[@]}"
fi
cmake --build build

export CAELESTIA_LIB_DIR="$PWD/build/lib"
export QML2_IMPORT_PATH="$PWD/build/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
export QS_ICON_THEME="${QS_ICON_THEME:-breeze-dark}"
export QT_IMAGEIO_MAXALLOC="${QT_IMAGEIO_MAXALLOC:-0}"

# Stop whichever installed shell service is running so the dev instance does
# not stack on top of it; the same unit is restarted on exit.
dev_unit=""
for unit in caelestia.service caelestia-shell.service; do
    if systemctl --user is-active --quiet "$unit"; then
        dev_unit="$unit"
        break
    fi
done
if [[ -n "$dev_unit" ]]; then
    systemctl --user stop "$dev_unit"
    trap 'systemctl --user start "$dev_unit"' EXIT
fi

# Non-NixOS hosts need the same nix GL wrapper the installed service uses.
gl_wrapper=""
for candidate in nixGLIntel nixGL; do
    if command -v "$candidate" >/dev/null; then
        gl_wrapper="$candidate"
        break
    fi
done
if [[ -z "$gl_wrapper" ]]; then
    gl_wrapper="$(ls -d /nix/store/*-nixGLIntel/bin/nixGLIntel 2>/dev/null | head -n1)"
fi

if [[ -n "$gl_wrapper" ]]; then
    "$gl_wrapper" qs -p "$PWD"
else
    qs -p "$PWD"
fi
