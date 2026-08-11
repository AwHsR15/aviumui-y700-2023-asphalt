#!/bin/bash
# Apply AviumUI device config + enable kernel BTF.
# Run after 02_sync_source.sh, before building.
set -e
SRC="${1:-$HOME/avium}"
DEV="$SRC/device/lenovo/asphalt"
KCFG="$SRC/kernel/lenovo/sm8475/arch/arm64/configs/vendor/asphalt_GKI.config"

echo "=== AviumUI device config ==="
MK="$DEV/lineage_asphalt.mk"
if grep -q "AVIUM_MAINTAINER" "$MK" 2>/dev/null; then
  echo "  already present, skipping"
else
  # Make sure we start on a new line - appending without this can glue our
  # block onto the end of the file's last line if it has no trailing newline.
  [ -n "$(tail -c1 "$MK" 2>/dev/null)" ] && echo "" >> "$MK"
  cat >> "$MK" <<'EOF'

## ---------------- AviumUI ----------------
AVIUM_MAINTAINER := your-name-here
AVIUM_SETTINGS_SOC_MODEL_NAME := Snapdragon 8+ Gen 1
AVIUM_SETTINGS_DEVICE_CODENAME := asphalt
AVIUM_VERSION_APPEND_TIME_OF_DAY := false
WITH_GMS := true
TARGET_FORCE_ENABLE_BLUR := true
AVIUM_FORCE_SET_FAKE_PROP := false
EOF
  echo "  written"
fi

echo
echo "=== kernel BTF (needed for eBPF tooling, bpftool, etc.) ==="
if [ -f "$KCFG" ]; then
  # Same trailing-newline caveat as above - been bitten by this once already.
  [ -n "$(tail -c1 "$KCFG" 2>/dev/null)" ] && echo "" >> "$KCFG"
  if grep -q '^CONFIG_DEBUG_INFO_BTF=y$' "$KCFG"; then
    echo "  already enabled"
  else
    echo "CONFIG_DEBUG_INFO_BTF=y" >> "$KCFG"
    echo "  enabled"
  fi
else
  echo "  !! $KCFG not found - check the path still matches upstream"
fi

echo
echo "Next: extract vendor blobs from your own device (04_extract_vendor_files.sh),"
echo "then build (05_build.sh)."
