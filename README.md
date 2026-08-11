# AviumUI for Lenovo Legion Y700 (2023) / TB320FC ("asphalt")

## 中文说明

这是给联想拯救者 Y700 2023 平板(TB320FC,设备代号 `asphalt`)自己编译的
**非官方 AviumUI 16.2.1** 系统(基于 Android 16)。[AviumUI](https://aviumui.org/)
官方支持设备列表里没有这台平板,这是完全从源码自己编出来的社区构建,
**不代表 AviumUI 团队,也没有得到他们的官方认可或支持**。

### 这个 ROM 有什么

- **系统**:AviumUI 16.2.1,Android 16,基于官方 `avium-16.2` 分支源码编译
- **内置 Google 服务**(编译时开了 `WITH_GMS := true`,不用另外刷 GApps)
- **内核额外开启了 BTF**(`CONFIG_DEBUG_INFO_BTF=y`)—— 这台设备官方 / 原版
  LineageOS 的内核默认不开这个,想在设备上跑 `bpftool` 之类的 eBPF 追踪工具
  就需要它
- **设备树和内核完全来自** [**lolipuru**](https://github.com/lolipuru) 的
  LineageOS 23.2 工作成果。这个仓库本身只是一份 repo manifest 加几个编译
  脚本,负责把源码正确地拼到一起编出来 —— **能让这台设备真正跑起来的功劳
  全部归功于 lolipuru**,这里不敢掠美。

### 下载

去 [Releases](../../releases) 页面下:刷机包(zip)、SHA256 校验和,以及
单独打包的 `boot.img`(有一份是干净的,另一份已经预先打好了 Magisk 补丁)。

刷机包超过了 GitHub 单文件 2GB 的上限,所以分成了两卷,刷机前要先合并:

```bash
# Linux / WSL
cat AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.00.part AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.01.part > AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
```

```cmd
:: Windows (cmd)
copy /b AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.00.part+AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip.01.part AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
```

合并完用 `SHA256SUMS.txt` 校验一下再刷,确保文件在传输过程中没有损坏。

### 怎么刷

标准的 LineageOS Recovery + A/B 无缝双系统 sideload 流程,和刷普通
LineageOS 没有区别:

1. **先备份数据** —— 下面的 Format data 这一步会清空设备内部存储的所有内容
2. 电脑上执行 `adb reboot recovery`,让设备重启进 Recovery
3. Recovery 菜单里:**Factory reset → Format data / factory reset**
4. 回到主菜单,选 **Apply update → Apply from ADB**
5. 平板显示等待接收后,电脑上执行:
   `adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip`
6. 刷完选 **Reboot system**。首次开机会比较慢(3–8 分钟),转圈别慌,是正常现象

**前提条件**:设备的 bootloader 要已解锁,而且要已经在跑一个基于 LineageOS
23.2 的系统(这样 Recovery 才认得这个包、才有能接受 sideload 的 Recovery)。
如果你现在还是联想原厂 ZUI 系统,得先想办法刷上兼容 LineageOS/AviumUI 的
Recovery —— 具体做法建议参考 lolipuru 的设备树仓库或相关论坛帖。

### 自己怎么编译

按顺序跑这五个脚本:

```bash
bash scripts/01_install_deps.sh           # 装编译依赖,要 root 权限
bash scripts/02_sync_source.sh            # 同步源码,大概会拉下来 120GB
bash scripts/03_apply_config.sh           # 写入 AviumUI 配置 + 开启内核 BTF
bash scripts/04_extract_vendor_files.sh   # 从你自己的设备提取厂商专有文件,需要 adb 连接
bash scripts/05_build.sh                  # 正式编译
```

`local_manifest.xml` 是第 2 步用来把 asphalt 设备树叠加到 AviumUI
manifest 上的清单文件。每个脚本里都写了详细注释,说明那些不太直观的地方,
以及**编译过程中真金白银踩过、花了不少时间才排查出来的坑**:

- **内存一定要给够**:soong 分析阶段单是这一步,内存峰值就能冲到
  **39GB 左右**。如果你是在只分了 32GB 内存的虚拟机 / WSL2 里编,
  会被系统悄无声息地 OOM 杀掉,编译日志里**看不到任何有用的报错信息**,
  表现就是"进程莫名其妙消失了"。建议至少给 40GB。
- **`repo sync` 千万别加 `--fail-fast`**,尤其是这种上千个子仓库的大树。
  只要有一个仓库同步时手气不好中断了,`--fail-fast` 会让整个同步流程
  直接中止,而那个倒霉仓库会留下"git 索引是空的、但文件已经落地在磁盘
  上"的半残状态。之后再跑 `repo sync` 时,它一看版本号对得上,就会认为
  这个仓库"已经同步完成"直接跳过 —— **但工作区其实是坏的**。后果是编译
  跑到很后面,会在某个看起来完全无辜的模块上报一堆莫名其妙的"缺少依赖"
  错误,极难联想到根因。遇到这种情况:进那个仓库目录 `git status` 看一眼,
  然后 `git reset --hard HEAD` 强制重建,或者干脆删掉整个仓库目录重新
  同步那一个。
- **`test/cts-root`** 这个测试套件里同时带了 32 位和 64 位两个版本的
  `CtsBionicRootTestCases`,两者会试图安装到同一个输出路径,导致 kati 在
  做许可证 / SBOM 检查那一步直接中止编译。这是 **AOSP 源码树本身的通用
  问题,跟这台设备没关系** —— 仓库里的 manifest 已经直接把这个项目从
  源码树里摘掉了,反正它只是 CTS 测试用的,对刷机包完全没用。
- **WSL2 的虚拟磁盘(vhdx)只会变大,不会自动变小**。在 WSL 里删文件,
  磁盘空间是不会还给 Windows 宿主机的,除非你先手动开一次稀疏模式:
  `wsl --manage <发行版名> --set-sparse true --allow-unsafe`

### 关于 Android 17 / `avium-17`

AviumUI 是有 `avium-17` 这条 manifest 分支的,lolipuru 的 asphalt 设备树
也有一条 `lineage-24.0-staging` 分支 —— 但截至这次构建,**内核仓库那边还
没有对应的 `lineage-24` 分支**,所以这台设备目前完整编出 A17 版本还不
现实。等上游把内核分支补上以后,理论上只需要把 `02_sync_source.sh` 里
指向的分支名改一下就能跟进,其余流程不用变。

另外顺带记一笔:实测发现,**Google 官方发布的 Android 17 GSI 通用系统镜像
在这台设备上直接刷是起不来的**,哪怕换上开启了 BTF 的自编译内核也一样,
统一报 `bpfloader-failed`。这看起来是"内核偏老 vs. 新版 GSI"这一类通用
问题(其他不少设备也踩过),社区里通常的解法是在**编译 GSI 那一侧**加个
补丁跳过 bpfloader 的版本检测,这已经超出了设备侧能解决的范围。把这个
结论记在这里,免得以后有人重复熬一整晚去查同一个问题。

### 免责声明

这是非官方的社区构建,**与 AviumUI、LineageOS 项目,联想公司,或
lolipuru 本人均无关联,不代表他们的立场**。刷第三方固件是有风险的操作,
如果中途出意外(比如突然断电、刷错分区等)有可能导致设备变砖 —— 一切
操作后果自负。开始之前,请务必先备份好原厂固件或保留一个能用的 Recovery
镜像,以便万一出问题时能够恢复。

---

## English

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

### Download

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

### Flashing

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

### Building it yourself

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

### About Android 17 / `avium-17`

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

### Disclaimer

Unofficial, community-built, not affiliated with the AviumUI or LineageOS
projects, Lenovo, or lolipuru. Flashing custom firmware can brick your
device if something goes wrong partway (power loss, wrong partition,
etc.) — you're doing this at your own risk. Keep a copy of your stock
firmware / a working recovery image before you start.
