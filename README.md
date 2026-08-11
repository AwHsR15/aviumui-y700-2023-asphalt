# AviumUI for Lenovo Legion Y700 (2023) / TB320FC ("asphalt")

Unofficial [AviumUI](https://aviumui.org/) 16.2.1 build (Android 16) for the
Lenovo Legion Y700 2023 tablet, codename **asphalt** (TB320FC). This device
is not on AviumUI's official supported-device list, so this is a
community/self build, not something the AviumUI team produced or endorses.

- **ROM:** AviumUI 16.2.1, Android 16, built from the official `avium-16.2` source
- **Google apps:** included (`WITH_GMS := true`)
- **Kernel:** built with `CONFIG_DEBUG_INFO_BTF=y` (the stock LineageOS build
  for this device does not enable this — it's needed if you want to run
  `bpftool`/eBPF-based tracing on-device)
- **Device tree / kernel:** all device support comes from
  [lolipuru](https://github.com/lolipuru)'s LineageOS 23.2 trees — this repo
  is only a manifest + build script pointing at that work. Full credit for
  making this device bootable at all goes to them.

## Download

See [Releases](../../releases) for the flashable zip, SHA256 checksum, and
a standalone `boot.img` (with and without Magisk pre-patched).

The zip is split into two parts because it's over GitHub's 2 GB per-file
limit. Reassemble before flashing:

```
# Linux / WSL
cat AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.00.part AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.01.part > AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip

# Windows (cmd)
copy /b AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.00.part+AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.01.part AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
```

Then check it against `SHA256SUMS.txt` before flashing.

## Flashing

Standard LineageOS-recovery-based A/B sideload flow:

1. Back up your data — the `Format data` step below wipes internal storage.
2. `adb reboot recovery`
3. In the recovery menu: **Factory reset → Format data / factory reset**
4. **Apply update → Apply from ADB**
5. On your PC: `adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip`
6. **Reboot system** when done. First boot is slow (3–8 min), that's normal.

You need an unlocked bootloader and a device already running a LineageOS
23.2-based ROM for this device (so the recovery can accept the package).
If you're coming from stock ZUI, flash a LineageOS/AviumUI-compatible
recovery first — see lolipuru's tree/thread for that.

## Building it yourself

```bash
bash scripts/01_install_deps.sh        # as root
bash scripts/02_sync_source.sh         # pulls ~120 GB of source
bash scripts/03_apply_config.sh
bash scripts/04_extract_vendor_files.sh   # needs your device connected via adb
bash scripts/05_build.sh
```

`local_manifest.xml` is what step 2 uses to pull in the asphalt device tree
on top of the AviumUI manifest. Each script has comments explaining the
non-obvious parts and the mistakes that cost real time to debug:

- **Memory:** soong's analysis phase alone peaks around **39 GB RAM**. If
  you're building in a VM/WSL2 with 32 GB assigned, it gets silently
  OOM-killed with nothing useful in the build log — looks like the build
  just vanished. Give it 40 GB+.
- **`repo sync --fail-fast` is a trap on a tree this size.** A single flaky
  clone can abort the whole sync mid-checkout, leaving that one repo with
  an empty git index but files still on disk. Subsequent `repo sync` runs
  see the ref already matches and call it done — but the working tree is
  actually broken, and you get bizarre "missing dependency" errors from
  soong much later, on a module that has nothing obviously wrong with it.
  If this happens: `git -C <broken-repo-path> status` and
  `git reset --hard HEAD`, or just delete and re-sync that one repo.
- **`test/cts-root`** ships 32-bit and 64-bit variants of
  `CtsBionicRootTestCases` that both try to install to the same output
  path, which aborts kati during the license/SBOM check. This is a generic
  AOSP tree issue, unrelated to this device — the included manifest just
  drops that project since it's CTS-only and irrelevant to a flashable ROM.
- **WSL2's vhdx only grows.** Deleting files inside WSL doesn't return disk
  space to the Windows host unless you enable sparse mode once:
  `wsl --manage <Distro> --set-sparse true --allow-unsafe`.

## About Android 17 / `avium-17`

AviumUI has an `avium-17` manifest branch, and lolipuru's asphalt device
tree has a `lineage-24.0-staging` branch — but as of this build, the
**kernel repo has no `lineage-24` branch**, so a full A17 build isn't
possible yet for this device. Once that lands, updating this build should
just be a matter of switching branches in `02_sync_source.sh`.

Separately: the stock Android 17 GSI (from Google) does **not** boot on
this device even with a custom kernel that has BTF enabled — it fails with
`bpfloader-failed`. This looks like the generic "old-kernel-vs-new-GSI"
issue several other devices have hit; the usual community fix is patching
the GSI build to skip the bpfloader version check, which is out of scope
for a device-side fix. Leaving this here so nobody else burns a night on
the same investigation.

## Disclaimer

Unofficial, community-built, not affiliated with the AviumUI or LineageOS
projects, Lenovo, or lolipuru. Flashing custom firmware can brick your
device if something goes wrong partway (power loss, wrong partition,
etc.) — you're doing this at your own risk. Keep a copy of your stock
firmware / a working recovery image before you start.

---

## 中文简介

这是给联想拯救者 Y700 2023 平板(TB320FC,设备代号 `asphalt`)编译的
**非官方 AviumUI 16.2.1** 系统(Android 16)。AviumUI 官方支持列表里没有
这台设备,这是自己从源码编出来的社区构建。

- 内置 Google 服务
- 内核额外开启了 BTF(原版 LineageOS 没有,方便做 eBPF 追踪)
- 设备树 / 内核全部来自 [lolipuru](https://github.com/lolipuru) 的
  LineageOS 23.2 工作成果,本仓库只是一份 manifest + 编译脚本

刷机包在 [Releases](../../releases) 页面,含 SHA256 校验和、单独的
`boot.img`。刷法就是标准的 LineageOS Recovery + `adb sideload` 流程,
详见上面英文部分或 Releases 页说明。

想自己编译的话,四个脚本按顺序跑就行,脚本注释里写了编译过程中踩过的坑
(内存要给够 40GB、`repo sync` 别加 `--fail-fast`、`test/cts-root` 要移除等)。

Android 17 版本目前还编不出来 —— 内核仓库还没有对应分支,设备树也只有半成品分支,等上游补完后照本仓库的流程改两行分支名即可跟进。
