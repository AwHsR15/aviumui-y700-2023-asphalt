#!/bin/bash
# Build AviumUI for asphalt.
#
# Requirements learned the hard way:
#   - >= 40 GB RAM (or RAM+swap) available to the build environment.
#     soong's analysis phase alone peaks at ~39 GB; 32 GB gets silently
#     OOM-killed with no useful error in the build log - it just looks like
#     the build "disappeared".
#   - >= 150 GB free disk for source + out/.
#   - If building inside WSL2, the vhdx only grows, it never shrinks on its
#     own. Enable sparse mode once so deleting files actually frees host
#     disk space:
#       wsl --manage <Distro> --set-sparse true --allow-unsafe
set -e
SRC="${1:-$HOME/avium}"
cd "$SRC"

echo "=== pre-flight ==="
for d in vendor/lenovo/asphalt vendor/lenovo/sm8475-common device/lenovo/asphalt kernel/lenovo/sm8475 vendor/avium; do
  [ -d "$SRC/$d" ] && printf "  OK      %s\n" "$d" || { printf "  MISSING %s\n" "$d"; exit 1; }
done
grep -n 'CONFIG_DEBUG_INFO_BTF' "$SRC/kernel/lenovo/sm8475/arch/arm64/configs/vendor/asphalt_GKI.config" || true
df -h "$HOME" | tail -1

export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL=C
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v ccache)
# Keep going on a single failed target instead of aborting the whole build.
# We hit this with out/target/product/asphalt/module-info.json, a
# dev-tooling helper file that has nothing to do with the flashable ROM -
# if ninja gets interrupted (OOM, disk full, host reboot) while writing it,
# it's left truncated and every subsequent build attempt fails trying to
# re-read it. -k 0 means "don't stop on failures", so the actual ROM
# packaging targets still complete even if that one file errors out.
export NINJA_ARGS="-k 0"
ccache -M 15G >/dev/null 2>&1 || true

source build/envsetup.sh
breakfast asphalt

date
time mka bacon -j"$(nproc --all)"
RC=$?
date
echo "exit code: $RC"

echo
echo "=== output ==="
ls -lh "$SRC"/out/target/product/asphalt/*.zip 2>/dev/null || echo "  no zip produced - check the log above"
df -h "$HOME" | tail -1
