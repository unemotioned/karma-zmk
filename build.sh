#!/usr/bin/env bash
set -euo pipefail

# NOTE: Change the keyboard names, controller type and etc from here.
shield_left='karma_left'
shield_right='karma_right'
controller='xiao_ble//zmk'
build_reset=false
venv_dir="$HOME/venv/zmk"

# absolute path to script's directory not where you ran it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

# activate python venv
source "$venv_dir/bin/activate"

# source Zephyr SDK env var
source "$SCRIPT_DIR/zephyr_env.sh"

# remove Homebrew injected flags only for this script
unset CFLAGS
unset CPPFLAGS
unset CXXFLAGS
unset LDFLAGS
unset CMAKE_OSX_ARCHITECTURES

# export zephyr to use project zephyr
export ZEPHYR_BASE="$ROOT_DIR/zephyr"
export WEST_TOPDIR="$ROOT_DIR"

# make sure west to use repo dir
cd "$ROOT_DIR"

# start timer
SECONDS=0

build_target() {
    local build_dir="$1"
    local shield="$2"
    local controller="$3"

    # NOTE: Add the following option in "$ west build" before the "--" to build cleanly
    # -p always \
    west build \
        -d "$build_dir" \
        -b "$controller" \
        -s zmk/app \
        -- \
        -DSHIELD="$shield" \
        -DZMK_CONFIG="$ROOT_DIR/config" \
        -DBOARD_ROOT="$PWD" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
}

build_target build/left "$shield_left" "$controller"
build_target build/right "$shield_right" "$controller"

if [ "$build_reset" = true ]; then
    build_target build/settings_reset settings_reset "$controller"
fi

mkdir -p output/bak

# backup to bak/
[ -f output/"$shield_left".uf2 ] &&
    mv output/"$shield_left".uf2 output/bak

[ -f output/"$shield_right".uf2 ] &&
    mv output/"$shield_right".uf2 output/bak

[ -f output/settings_reset.uf2 ] &&
    mv output/settings_reset.uf2 output/bak

# copy the built uf2 to output/
[ -f build/left/zephyr/zmk.uf2 ] &&
    cp build/left/zephyr/zmk.uf2 output/"$shield_left".uf2

[ -f build/right/zephyr/zmk.uf2 ] &&
    cp build/right/zephyr/zmk.uf2 output/"$shield_right".uf2

[[ "$build_reset" = true && -f build/settings_reset/zephyr/zmk.uf2 ]] &&
    cp build/settings_reset/zephyr/zmk.uf2 output/settings_reset.uf2

echo -e "\n----------------------------------------------"
echo -e "\n Build done. (took ${SECONDS}s)"
echo -e "\n uf2 files are copied to the output directory."
echo -e "\n----------------------------------------------\n"

read -rp 'Open output directory with finder? [Y/n]: ' answer
if [[ -z "${answer,,}" || "${answer,,}" == 'y' ]]; then
    open ./output
fi
