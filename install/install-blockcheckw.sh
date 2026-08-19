#!/bin/sh
set -e
INSTALL_DIR="/opt/Z2Vibecheck/bin"
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64) BA="arm64" ;;
    armv7l|armv7) BA="armv7" ;;
    x86_64|amd64) BA="x86_64" ;;
    *) echo "ERROR: $ARCH"; exit 1 ;;
esac
mkdir -p "$INSTALL_DIR"
VERSION=$(wget -qO- https://api.github.com/repos/rcd27/blockcheckw/releases/latest 2>/dev/null | grep tag_name | head -1 | cut -d'"' -f4)
[ -z "$VERSION" ] && VERSION="v0.9.2"
cd /tmp
wget -q "https://github.com/rcd27/blockcheckw/releases/download/${VERSION}/blockcheckw-linux-${BA}.tar.gz"
tar xzf "blockcheckw-linux-${BA}.tar.gz"
mv -f blockcheckw "$INSTALL_DIR/blockcheckw"
chmod +x "$INSTALL_DIR/blockcheckw"
rm -f "blockcheckw-linux-${BA}.tar.gz"
mkdir -p /usr/local/bin
ln -sf "$INSTALL_DIR/blockcheckw" /usr/local/bin/blockcheckw
echo "blockcheckw installed to $INSTALL_DIR"
