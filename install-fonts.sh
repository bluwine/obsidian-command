#!/usr/bin/env bash
# install-fonts.sh
#
# Installs the bundled JetBrainsMono Nerd Font (Mono variant, 4 weights)
# into the current user's font directory and refreshes the font cache.
#
# Linux:  ~/.local/share/fonts/JetBrainsMonoNerdFont/
# macOS:  ~/Library/Fonts/   (no per-folder grouping)
#
# Usage:
#     ./install-fonts.sh
#
# After it finishes, set Obsidian's monospace font to "JetBrainsMono Nerd
# Font Mono" (Settings → Appearance → Monospace font) so the powerline
# glyphs in the Catppuccin Mocha prompt render correctly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/fonts"

if [ ! -d "$SRC" ] || ! ls "$SRC"/*.ttf >/dev/null 2>&1; then
  echo "error: no .ttf files found in $SRC" >&2
  echo "       expected the plugin's bundled fonts to live there." >&2
  exit 1
fi

case "$(uname -s)" in
  Linux)
    DEST="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
    mkdir -p "$DEST"
    cp -v "$SRC"/*.ttf "$DEST/"
    echo
    echo "==> Refreshing font cache (fc-cache -f)..."
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$DEST"
    else
      echo "warning: fc-cache not found; the font may not be visible until you log out." >&2
    fi
    ;;
  Darwin)
    DEST="$HOME/Library/Fonts"
    mkdir -p "$DEST"
    cp -v "$SRC"/*.ttf "$DEST/"
    ;;
  *)
    echo "error: unsupported OS '$(uname -s)'." >&2
    echo "       Copy $SRC/*.ttf into your platform's user font folder manually." >&2
    exit 1
    ;;
esac

echo
echo "==> Installed:"
ls -lh "$DEST"/JetBrainsMonoNerdFontMono-*.ttf 2>/dev/null || true
echo
echo "Open Obsidian → Settings → Appearance → Monospace font and"
echo "type 'JetBrainsMono Nerd Font Mono' to use it in the Command terminal."
