#!/usr/bin/env bash
set -euo pipefail

# opencode-node-build one-click installer
# Downloads a pre-built tarball (no git clone needed - works on old/slow networks)
# Bundled Node.js compiled with -march=x86-64 (SSE2 baseline) for old CPUs
# like Intel Core 2 (no SSE 4.2/AVX required)

INSTALL_DIR="${HOME}/.opencode-node"
DOWNLOAD_URL="https://github.com/01luyicheng/opencode-node-build/releases/download/v1.0.0/opencode-node-v1.tar.gz"

echo "============================================"
echo "  opencode.ai (Node.js build) Installer"
echo "============================================"
echo ""

# Check OS
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: This installer only supports Linux."
  exit 1
fi

# Check architecture
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "ERROR: This build only supports x86_64."
  exit 1
fi

# Check curl
if ! command -v curl &>/dev/null; then
  echo "Installing curl..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq curl xz-utils
  else
    echo "ERROR: Please install curl and xz-utils first."
    exit 1
  fi
fi

# Check xz
if ! command -v xz &>/dev/null; then
  echo "Installing xz-utils..."
  sudo apt-get install -y -qq xz-utils 2>/dev/null || true
fi

# Clean old install (since we changed from git to tarball)
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "Cleaning old git-based installation..."
  rm -rf "$INSTALL_DIR"
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download tarball
echo "Downloading opencode (~33MB, with retries)..."
echo ""
TARBALL="/tmp/opencode-node-v1.tar.gz"

# Use curl with resume support and retries
curl -L --retry 5 --retry-delay 3 --retry-connrefused -C - \
  -o "$TARBALL" \
  "$DOWNLOAD_URL"

echo ""
echo "Download complete. Extracting..."

# Extract
tar xzf "$TARBALL" -C "$INSTALL_DIR"
rm -f "$TARBALL"

# Decompress bundled Node.js
if [[ ! -f "$INSTALL_DIR/node" ]]; then
  echo "Decompressing bundled Node.js..."
  xz -d -k "$INSTALL_DIR/node.xz"
fi

# Make launcher executable
chmod +x "$INSTALL_DIR/opencode"
chmod +x "$INSTALL_DIR/node"

echo "✓ Files installed to $INSTALL_DIR"

# Add to PATH
SHELL_NAME=$(basename "$SHELL")
RC_FILE=""
case "$SHELL_NAME" in
  bash) RC_FILE="$HOME/.bashrc" ;;
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
  *)    RC_FILE="$HOME/.profile" ;;
esac

PATH_LINE="export PATH=\"\$HOME/.opencode-node:\$PATH\""
if ! grep -qF ".opencode-node" "$RC_FILE" 2>/dev/null; then
  echo "" >> "$RC_FILE"
  echo "# opencode (Node.js build)" >> "$RC_FILE"
  echo "$PATH_LINE" >> "$RC_FILE"
  echo "✓ Added to PATH in $RC_FILE"
else
  echo "✓ PATH already configured"
fi

# Verify
echo ""
echo "============================================"
echo "  Installation complete!"
echo "============================================"
echo ""
echo "  Install location: $INSTALL_DIR"
echo "  Run: opencode --version"
echo ""
echo "  To use immediately in this terminal:"
echo "    export PATH=\"\$HOME/.opencode-node:\$PATH\""
echo "    opencode --help"
echo ""

# Test run
export PATH="$INSTALL_DIR:$PATH"
if "$INSTALL_DIR/opencode" --version &>/dev/null; then
  echo "  ✓ Verified: opencode $("$INSTALL_DIR/opencode" --version 2>/dev/null)"
else
  echo "  ⚠ Verification failed. Try running: $INSTALL_DIR/opencode --version"
fi
