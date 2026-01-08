#!/bin/sh
set -e

REPO="ericzakariasson/duster"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin) OS="macos" ;;
  linux) OS="linux" ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64) ARCH="x86_64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Linux only has x86_64 builds
if [ "$OS" = "linux" ]; then
  ARCH="x86_64"
fi

ASSET="duster-${OS}-${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

# Determine install directory
if [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
  USE_SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  INSTALL_DIR="/usr/local/bin"
  USE_SUDO="sudo"
else
  INSTALL_DIR="$HOME/.local/bin"
  USE_SUDO=""
  mkdir -p "$INSTALL_DIR"
fi

echo "Downloading duster for ${OS}-${ARCH}..."
curl -fsSL "$URL" -o /tmp/duster.tar.gz

echo "Installing to ${INSTALL_DIR}..."
tar -xzf /tmp/duster.tar.gz -C /tmp
$USE_SUDO mv /tmp/duster "$INSTALL_DIR/duster"
$USE_SUDO chmod +x "$INSTALL_DIR/duster"
rm /tmp/duster.tar.gz

# Check if install dir is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo ""
  echo "Adding $INSTALL_DIR to PATH..."
  
  SHELL_NAME=$(basename "$SHELL")
  case "$SHELL_NAME" in
    zsh)
      PROFILE="$HOME/.zshrc"
      ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        PROFILE="$HOME/.bashrc"
      else
        PROFILE="$HOME/.bash_profile"
      fi
      ;;
    fish)
      PROFILE="$HOME/.config/fish/config.fish"
      ;;
    *)
      PROFILE="$HOME/.profile"
      ;;
  esac
  
  if [ -f "$PROFILE" ]; then
    if ! grep -q "$INSTALL_DIR" "$PROFILE" 2>/dev/null; then
      echo "" >> "$PROFILE"
      echo "# Added by duster installer" >> "$PROFILE"
      echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE"
      echo "Added to $PROFILE"
      echo ""
      echo "Run 'source $PROFILE' or restart your terminal to use duster."
    fi
  fi
fi

echo ""
echo "✓ duster installed successfully!"
echo ""
echo "Run 'duster --help' to get started."
