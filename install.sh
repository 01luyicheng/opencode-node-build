#!/usr/bin/env bash
set -euo pipefail

# opencode-node-build one-click installer
# Bundled Node.js compiled with -march=x86-64 (SSE2 baseline) for old CPUs
# like Intel Core 2 (no SSE 4.2/AVX required)

INSTALL_DIR="${HOME}/.opencode-node"
REPO_URL="https://github.com/01luyicheng/opencode-node-build.git"

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

# Check git
if ! command -v git &>/dev/null; then
  echo "Installing git..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq git xz-utils
  else
    echo "ERROR: Please install git and xz-utils first."
    exit 1
  fi
fi

# Check xz
if ! command -v xz &>/dev/null; then
  echo "Installing xz-utils..."
  sudo apt-get install -y -qq xz-utils 2>/dev/null || true
fi

# Clone or update
echo ""
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Updating existing installation..."
  cd "$INSTALL_DIR"
  git fetch --quiet
  git reset --hard origin/main --quiet
else
  echo "Cloning opencode-node-build..."
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi
echo "✓ Source code ready"

# Decompress bundled Node.js (if not already)
if [[ ! -f "$INSTALL_DIR/node" ]]; then
  echo "Decompressing bundled Node.js..."
  xz -d -k "$INSTALL_DIR/node.xz"
  chmod +x "$INSTALL_DIR/node"
fi

# Make launcher executable
chmod +x "$INSTALL_DIR/opencode"
chmod +x "$INSTALL_DIR/node"

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
