#!/usr/bin/env bash
set -euo pipefail

# opencode-node-build one-click installer
# Installs opencode.ai built for Node.js (compatible with older CPUs without SSE 4.2/AVX)

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

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js is not installed."
  echo "Please install Node.js >= 22 from https://nodejs.org/"
  echo ""
  echo "Quick install (Ubuntu/Debian):"
  echo "  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -"
  echo "  sudo apt-get install -y nodejs"
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [[ "$NODE_VERSION" -lt 22 ]]; then
  echo "ERROR: Node.js >= 22 is required (you have $(node -v))."
  echo "This build uses the built-in node:sqlite module available in Node 22+."
  echo "Please upgrade Node.js: https://nodejs.org/"
  exit 1
fi
echo "✓ Node.js $(node -v) found"

# Check build tools for node-pty
if ! command -v gcc &>/dev/null || ! command -v make &>/dev/null; then
  echo ""
  echo "WARNING: build-essential (gcc/make) not found."
  echo "The @lydell/node-pty native module needs to be compiled."
  echo "Installing build-essential and python3..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq build-essential python3
  elif command -v yum &>/dev/null; then
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y python3
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm base-devel python3
  else
    echo "ERROR: Could not install build tools automatically."
    echo "Please install gcc, make, and python3 manually, then re-run this installer."
    exit 1
  fi
fi
echo "✓ Build tools available"

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

# Install dependencies (compiles node-pty)
echo ""
echo "Installing dependencies (compiling @lydell/node-pty)..."
echo "  This may take a minute on older CPUs..."
npm install --no-audit --no-fund --silent
echo "✓ Dependencies installed"

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
if opencode --version &>/dev/null; then
  echo "  ✓ Verified: opencode $(opencode --version 2>/dev/null)"
else
  echo "  ⚠ Verification failed. Try running: node $INSTALL_DIR/opencode.mjs --version"
fi
