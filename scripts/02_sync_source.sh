#!/bin/bash
# Sync AviumUI 16.2 source + asphalt device tree.
# Usage: bash 02_sync_source.sh [target dir]   (default: ~/avium)
#
# Space/RAM notes (measured on this build):
#   - full source checkout: ~120 GB
#   - out/ during a full build: ~110-140 GB (peaks higher during packaging)
#   - soong analysis alone peaks at ~39 GB RAM -> give the build VM at least 40 GB
set -e
SRC="${1:-$HOME/avium}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_SRC="$HERE/../local_manifest.xml"

mkdir -p "$HOME/bin"
if [ ! -x "$HOME/bin/repo" ]; then
  curl -s https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
  chmod a+x "$HOME/bin/repo"
fi
export PATH="$HOME/bin:$PATH"

git config --global user.name  "${GIT_USER_NAME:-Your Name}"
git config --global user.email "${GIT_USER_EMAIL:-you@example.com}"
git config --global color.ui true
git config --global --add safe.directory '*'
git config --global http.postBuffer 524288000
git config --global core.compression 0

mkdir -p "$SRC" && cd "$SRC"
repo init -u https://github.com/AviumUI/android_manifests -b avium-16.2 --git-lfs --depth=1

mkdir -p .repo/local_manifests
cp "$MANIFEST_SRC" .repo/local_manifests/local_manifest.xml

echo
echo "=== syncing (this takes a while) ==="
# NOTE: do NOT add --fail-fast on a large multi-hundred-repo sync.
# A single flaky repo can abort the whole sync mid-checkout and leave that
# repo with an EMPTY git index but files still on disk. `repo sync` will
# then silently consider it "already synced" on retry, because the ref
# matches - but the working tree is actually broken (soong will fail much
# later with confusing "missing dependency" errors on random modules built
# from that repo, e.g. external/cronet). If a sync fails partway, inspect
# `git -C <path> status` in the affected repo and `git reset --hard HEAD`
# it, or just delete the repo dir and re-sync.
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags

echo
echo "=== result ==="
du -sh "$SRC"
for d in device/lenovo/asphalt device/lenovo/sm8475-common kernel/lenovo/sm8475 vendor/lineage vendor/avium; do
  [ -d "$SRC/$d" ] && echo "  OK      $d" || echo "  MISSING $d"
done
echo
echo "Next: bash 03_apply_config.sh"
