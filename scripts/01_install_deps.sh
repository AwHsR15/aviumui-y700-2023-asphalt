#!/bin/bash
# Install AOSP/LineageOS build dependencies (Debian/Ubuntu, e.g. WSL2 Ubuntu 24.04)
# Run as root: sudo bash 01_install_deps.sh   (or: wsl -d Ubuntu -u root -- bash 01_install_deps.sh)
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq \
  git git-lfs gnupg flex bison build-essential zip unzip curl \
  zlib1g-dev libc6-dev-i386 x11proto-dev libx11-dev \
  lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc fontconfig \
  libncurses-dev libssl-dev libelf-dev bc rsync ccache \
  python3 python3-pip python-is-python3 \
  lzop liblz4-tool squashfs-tools imagemagick schedtool \
  libsdl1.2-dev libwxgtk3.2-dev pngcrush jq

git lfs install --system

echo
echo "=== verify ==="
MISSING=0
for t in git git-lfs python3 make clang bison flex zip unzip rsync ccache lz4 jq xsltproc; do
  if command -v "$t" >/dev/null 2>&1; then printf "%-10s OK\n" "$t"; else printf "%-10s MISSING\n" "$t"; MISSING=1; fi
done
[ "$MISSING" = "0" ] && echo "All dependencies ready." || echo "Some tools are missing, see above."
