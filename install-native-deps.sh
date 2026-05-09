#!/usr/bin/env bash
# install-native-deps.sh
#
# Compiles node-pty's native bindings and installs the runtime files into
# the Command plugin folder. Run this on the Linux main computer
# (NOT the lab macOS box — node-pty's native binary must match the OS/arch
# where Obsidian actually runs).
#
# Prerequisites on Debian/Ubuntu:
#     sudo apt install nodejs npm build-essential python3
# On Arch:
#     sudo pacman -S nodejs npm base-devel python
#
# Usage:
#     ./install-native-deps.sh
#     VAULT_PLUGIN_DIR=/path/to/vault/.obsidian/plugins/command ./install-native-deps.sh
#
# After this finishes, reload Obsidian (or toggle the Command
# plugin off/on) so it picks up the freshly-installed backend.

set -euo pipefail

NODE_PTY_VERSION="1.1.0"

# Resolve the plugin directory. Default assumes the script is being run
# from inside the plugin folder itself (which is the case when it ships
# alongside the built artifacts via Syncthing).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PLUGIN_DIR="$SCRIPT_DIR"
VAULT_PLUGIN_DIR="${VAULT_PLUGIN_DIR:-$DEFAULT_PLUGIN_DIR}"

if [ ! -f "$VAULT_PLUGIN_DIR/manifest.json" ]; then
  echo "error: $VAULT_PLUGIN_DIR does not look like the command plugin folder" >&2
  echo "       (manifest.json not found). Set VAULT_PLUGIN_DIR explicitly." >&2
  exit 1
fi

NATIVE_DIR="$VAULT_PLUGIN_DIR/native/node-pty"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Compiling node-pty@$NODE_PTY_VERSION in $TMP_DIR"
cd "$TMP_DIR"
npm init -y >/dev/null
npm install --no-audit --no-fund --no-save "node-pty@$NODE_PTY_VERSION"

SRC="$TMP_DIR/node_modules/node-pty"
BIN="$SRC/build/Release/pty.node"

if [ ! -f "$BIN" ]; then
  echo "error: node-gyp did not produce $BIN" >&2
  echo "       Confirm build-essential and python3 are installed." >&2
  exit 1
fi

echo "==> Copying runtime files to $NATIVE_DIR"
rm -rf "$NATIVE_DIR"
mkdir -p "$NATIVE_DIR/lib" "$NATIVE_DIR/build/Release"
cp "$SRC/package.json" "$NATIVE_DIR/"
cp -R "$SRC/lib/." "$NATIVE_DIR/lib/"
cp "$BIN" "$NATIVE_DIR/build/Release/"
if [ -f "$SRC/build/Release/spawn-helper" ]; then
  cp "$SRC/build/Release/spawn-helper" "$NATIVE_DIR/build/Release/"
fi

echo
echo "==> Installed:"
ls -lh "$NATIVE_DIR/build/Release/"
echo
echo "Reload the Command plugin in Obsidian to pick up the new backend."
