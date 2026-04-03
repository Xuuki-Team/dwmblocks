#!/bin/bash
# Build both dwmblocks variants

set -e

DWMB_DIR="$HOME/dwmblocks"

echo "Building dwmblocks-jnash..."
cd "$DWMB_DIR"
cp config.h config.h.backup 2>/dev/null || true
make clean
make
sudo cp dwmblocks /usr/local/bin/dwmblocks-jnash
echo "✓ dwmblocks-jnash built"

echo ""
echo "Building dwmblocks-admin..."
cp config-admin.h config.h
make clean
make
sudo cp dwmblocks /usr/local/bin/dwmblocks-admin
echo "✓ dwmblocks-admin built"

echo ""
echo "Restoring jnash config..."
cp config.h.backup config.h
make clean
make
sudo cp dwmblocks /usr/local/bin/dwmblocks
echo "✓ dwmblocks (jnash default) restored"

echo ""
echo "Done! Binaries:"
ls -la /usr/local/bin/dwmblocks* | grep -E "(dwmblocks$|dwmblocks-)"
