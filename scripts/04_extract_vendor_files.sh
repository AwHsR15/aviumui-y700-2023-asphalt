#!/bin/bash
# Extract vendor proprietary blobs from a running device over adb.
# Your tablet must be on a LineageOS/AviumUI-based ROM, USB debugging on,
# and unlocked. Root (adb root) is required to read /vendor.
#
# If you're running this from WSL2 and adb.exe lives on the Windows side,
# point ADB_SERVER_SOCKET at the Windows host IP instead of installing a
# second adb server in WSL - e.g.:
#   export ADB_SERVER_SOCKET=tcp:$(ip route show default | awk '{print $3}'):5037
# and make sure adb.exe on Windows was started with `adb -a -P 5037 nodaemon server`
# so it listens on all interfaces, not just localhost.
set -e
SRC="${1:-$HOME/avium}"

adb devices
adb root || true
sleep 3
adb wait-for-device

cd "$SRC/device/lenovo/asphalt"
PYTHONPATH="$SRC/tools/extract-utils" python3 extract-files.py adb

echo
echo "=== result ==="
for d in "$SRC/vendor/lenovo/asphalt" "$SRC/vendor/lenovo/sm8475-common"; do
  if [ -d "$d" ]; then
    echo "  OK      $d  ($(du -sh "$d" 2>/dev/null | cut -f1))"
  else
    echo "  MISSING $d"
  fi
done
echo
echo "Next: bash 05_build.sh"
