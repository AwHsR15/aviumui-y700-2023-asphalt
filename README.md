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
  LineageOS 23.2 工作成果(GitHub 上能查到的提交记录里,设备树仓库从
  2025-07-14 的初始骨架开始就是他一路写起来的,提交量遥遥领先其他贡献者)。
  这个仓库本身只是一份 repo manifest 加几个编译脚本,负责把源码正确地
  拼到一起编出来。另外,这台设备最早的社区适配 / 内核与 HAL 源码这块,
  按流传的 LineageOS 23.2 非官方构建帖里的致谢,还要感谢 **mickey36736**
  (设备适配)和 **soralis0912**(内核与 HAL 源码,GitHub 上确实有他做过
  的联想相关逆向工具)—— **这台设备能跑起来,是这几位一起的功劳**,这里
  不敢掠美。

### 下载

去 [Releases](../../releases) 页面下:刷机包(zip)、单独提取出来的
`recovery.img`(刷机第一步要用,见下面教程)、单独打包的 `boot.img`
(有一份是干净的,另一份已经预先打好了 Magisk 补丁)、以及 SHA256 校验和。

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

有两种方式,**推荐用一键脚本**,手动流程留在下面供参考和排查用。

这个包本身就是完整的系统,**不需要事先装过别的系统再"升级"过来** ——
不管你现在是联想原厂 ZUI,还是已经在跑 LineageOS/AviumUI,流程都一样:
先用 fastboot 刷一次这个包自带的 Recovery,再用那个 Recovery 去 sideload
整个包。

#### 方式一:一键脚本(推荐)

仓库里的 [`flasher/`](flasher/) 文件夹是一个 Windows 一键刷机工具,
下载整个文件夹后:

1. 把 Release 里下载的文件丢进 `flasher/images/`(分卷不用自己合并)
2. 平板打开 USB 调试,用数据线接电脑(**必须插长边那个口**)
3. 双击 `一键刷机.bat`,按提示走

脚本会自动处理这些事:

- 缺 adb / fastboot 会自动从 Google 官方下载,不需要另外装 Android SDK
  (国内网络可能需要代理,下不动的话说明里有手动方案)
- 自动合并 `.00.part` / `.01.part` 分卷,合并前先检查磁盘空间够不够
- 校验 SHA256,防止下载损坏导致刷到一半失败
- **校验机型** —— 确认连的确实是 Y700 2023 才继续,防止手滑刷错设备
- 检查 bootloader 解锁状态、电量
- 自动识别设备当前在哪种模式(系统 / Recovery / sideload / fastboot)
- 自动识别 A/B 活动槽位,刷 boot 时刷到对的槽
- 出错时给出具体的排查建议,并把完整日志存成文件方便反馈

除了完整刷机,菜单里还有单独刷 boot(装/去 root)、重置 super 分区
(修 status 7)、以及只做检查不写入的选项。

详细说明见 [`flasher/使用说明.txt`](flasher/使用说明.txt)。

#### 方式二:手动操作

如果你更想清楚每一步在干什么,或者一键脚本在你机器上跑不起来,
可以照下面的步骤手动来。这也是脚本内部实际执行的流程。

#### 刷机前需要确认

- [ ] **bootloader 已解锁**(这是唯一真正的前提条件,不管你现在跑的是
      什么系统)
- [ ] 电脑上装好了 **adb 和 fastboot**(Android SDK Platform Tools),
      命令行里能正常识别
- [ ] **USB 数据线插在平板长边那个接口**(短边那个口不能用来传数据 /
      刷机,插错了 `adb devices` / `fastboot devices` 会看不到设备)
- [ ] 电量至少 50%
- [ ] 刷机包已经按上面的方法合并好、`SHA256SUMS.txt` 校验通过
- [ ] 额外从 [Releases](../../releases) 下载 **`recovery.img`**(单独
      打包好的,是从刷机包里原样提取出来的,用来在刷机前先让设备认得
      这个包)

关于机型:不管你这台是**国行还是全球版**,理论上都能刷 —— 我们自己那台
就是国行渠道买的二手机。之前折腾原厂 ZUI 系统时确实撞过联想自己加的
"区域校验"红字报错,但那是联想 ZUI 系统固件里专有的检查逻辑;LineageOS
系(以及基于它的 AviumUI)用的 `vendor_boot` 是完全独立编译出来的开源版本,
不含联想那段专有代码,实测流程里也确实再没遇到过这类问题。

#### 详细步骤

1. **先备份数据**。下面 Format data 那一步会清空 `/data` 分区 ——
   已安装的应用、应用内部数据、账号登录状态等全部清空。`/sdcard` 里的
   照片、下载文件等如果重要,建议先用 `adb pull` 导出一份。

2. 让设备进入 **fastboot(bootloader)模式**。如果当前系统已经开着
   USB 调试,电脑上执行:
   ```bash
   adb reboot bootloader
   ```
   如果不确定/USB 调试没开(比如设备现在还是原厂系统刚拿到手),用
   **音量键 -(下) + 电源键**长按组合键强制进入。进去后电脑上确认能
   识别到:
   ```bash
   fastboot devices
   ```
   应该能看到一行"序列号 + fastboot"。

3. 把刚下载的 `recovery.img` 刷进两个槽位(这台设备是 A/B 双系统,两个
   槽都要刷一遍):
   ```bash
   fastboot flash recovery_a recovery.img
   fastboot flash recovery_b recovery.img
   ```

4. 重启进入刚刷好的 Recovery:
   ```bash
   fastboot reboot recovery
   ```
   平板会进入一个 **AviumUI Recovery 菜单**(顶部写着
   `AviumUI Recovery Version 16.2.1`)。

5. 在 Recovery 菜单里,用**音量键**上下移动光标、**电源键**确认,依次
   选择:**Factory reset → Format data / factory reset**,确认执行。
   屏幕会滚动出现类似
   `Wiping data... / Formatting /data... / Data wipe complete.`
   的文字,这是正常的,等它跑完。

6. 返回 Recovery 主菜单,选择:**Apply update → Apply from ADB**。
   屏幕会显示类似
   `Now send the package you want to apply to the device with "adb sideload <filename>"...`
   —— 这说明设备已经在等待接收了。

7. 回到电脑,在刷机包所在目录下执行:
   ```bash
   adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
   ```
   这个包 2GB+,传输大概要 5–8 分钟(具体看你的数据线和 USB 口速度),
   命令行会滚动显示百分比进度,类似 `serving: '...' (~50%)`。

8. **⚠️ 有一个很容易让人虚惊一场的地方**:传输结束后,Recovery 屏幕上
   有时会**残留显示上一次尝试失败时留下的旧文字**,比如
   `Install completed with status 3. Installation aborted.`
   看着像是这次也失败了,但其实**这只是屏幕没刷新干净,显示的是过时
   信息**。判断刷机到底成没成功,可以重新进一次 **Apply update** 菜单
   看它是不是已经不再提示"发送包",或者直接进第 9 步重启,系统能不能
   正常进去才是最终判断标准。

9. 回到 Recovery 主菜单,选择 **Reboot → System**,进入新系统。**首次
   开机会明显比平时慢很多**(3–8 分钟内的转圈、黑屏都是正常现象,是在
   做首次的 dex 优化和 A/B 分区切换),这个阶段千万别断电或强制重启。

#### 常见问题排查

- **`adb devices` / `fastboot devices` 看不到设备,或显示 `unauthorized`**:
  先确认数据线支持数据传输(不是纯充电线),换个 USB 口试试(优先主板
  后置接口,避免用前置面板或 USB Hub),然后看平板屏幕上是否有调试
  授权弹窗需要确认。
- **Recovery 里的英文菜单看不太懂**:标准操作方式是音量键上下移动光标、
  电源键确认,跟大多数 Android 官方 Recovery 一样。
- **传输结束后出现 `Install completed with status 3` 之类的失败字样**:
  先别急着重刷。这行字有时候是**上一次尝试残留在屏幕上、没刷新掉的旧
  信息**,不代表这一次真的失败了。可以重新进一次 **Apply update →
  Apply from ADB** 看提示是否正常,或者直接大胆进第 9 步重启 —— 系统
  能不能正常开机,才是最终判断标准,比屏幕上这行字可靠得多。
- **重启后卡在 logo 界面很久不动**:首次开机确实会比平时明显久,耐心
  等 5–10 分钟;如果超过 15 分钟屏幕还是一动不动,再考虑排查问题。
- **想刷回原来的系统**:如果原来的系统也是这种 payload.bin 格式的
  sideload 包,重新走一遍上面第 5–9 步(不用再重新刷 recovery),
  `adb sideload` 换成你原来那个包的文件名即可。

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

### 这是官方支持的设备吗?

不是,而且不会自动变成官方支持。AviumUI 对官方设备有自己的
[准入政策](https://github.com/AviumUI-Devices/official_devices/blob/main/README.md),
`asphalt` 目前不在其中。也就是说这个 ROM **不会跟着官方走 OTA 更新**,
后续版本都得从这个仓库的 Release 页面手动下载。

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
  [lolipuru](https://github.com/lolipuru)'s LineageOS 23.2 trees (their
  commit history shows they've been the primary author since the initial
  skeleton on 2025-07-14, by a wide margin over any other contributor) —
  this repo is only a manifest + build script pointing at that work.
  The earliest community bring-up of this device also credits
  **mickey36736** (device) and **soralis0912** (kernel/HAL source —
  who does have public Lenovo-related reverse-engineering work on
  GitHub) per the original unofficial LineageOS 23.2 build thread. Full
  credit for making this device bootable at all goes to all of them.

### Download

See [Releases](../../releases) for the flashable zip, a separately
extracted `recovery.img` (needed for step 1 of flashing below), a
standalone `boot.img` (with and without Magisk pre-patched), and the
SHA256 checksums.

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

Two options — **the one-click script is recommended**; the manual steps
are kept below for reference and troubleshooting.

This package is a complete, standalone system — **you don't need to have
some other ROM already installed first.** Whether you're currently on
stock ZUI or already on a LineageOS/AviumUI-based ROM, the process is the
same: flash the recovery that ships inside this package via fastboot,
then use that recovery to sideload the package itself.

#### Option 1: one-click script (recommended)

The [`flasher/`](flasher/) folder contains a Windows one-click flashing
tool. Download the whole folder, then:

1. Drop the files from Releases into `flasher/images/` (no need to merge
   the split parts yourself)
2. Enable USB debugging, connect the tablet (**use the port on the long
   edge** — the short-edge port can't be used for flashing)
3. Double-click `一键刷机.bat` and follow the prompts

It handles:

- Downloads adb/fastboot from Google automatically if they're missing, so
  no separate Android SDK install needed (it's not bundled in the repo —
  that's Google's Platform Tools, with its own license)
- Auto-merging the `.00.part` / `.01.part` split archive, with a free-space
  check first
- SHA256 verification, so a corrupted download fails early instead of
  halfway through flashing
- **Device model verification** — refuses to proceed unless it's actually
  a Y700 2023, so you can't accidentally flash the wrong device
- Bootloader unlock state and battery level checks
- Auto-detecting which mode the device is currently in (system / recovery
  / sideload / fastboot)
- Auto-detecting the active A/B slot when flashing boot images
- Specific troubleshooting hints on failure, plus a full log file you can
  attach to a bug report

Besides a full flash, the menu also offers flashing boot images alone
(add/remove root), resetting the super partition (fixes status 7), and a
check-only mode that writes nothing.

The script's UI is in Chinese; see [`flasher/使用说明.txt`](flasher/使用说明.txt).
If you'd prefer an English version, open an issue and I'll add one.

#### Option 2: manual steps

If you'd rather see exactly what's happening, or the script doesn't work
on your machine, follow the steps below — this is what the script does
internally anyway.

#### Before you start

- [ ] **Unlocked bootloader** (this is the only real prerequisite,
      regardless of what's currently on the device)
- [ ] **adb and fastboot installed** (Android SDK Platform Tools) and
      working from your PC's command line
- [ ] **USB cable plugged into the port on the long edge of the tablet**
      (the short-edge port won't do data transfer / flashing — if
      `adb devices`/`fastboot devices` shows nothing, this is the first
      thing to check)
- [ ] Battery at least 50%
- [ ] The zip is reassembled and `SHA256SUMS.txt` checks out
- [ ] You've also downloaded **`recovery.img`** from Releases (extracted
      straight out of the flashable zip, used to bootstrap step 1 below)

On region: this should work regardless of whether your unit is a China
retail (国行) or global (ROW) unit — ours is a secondhand China-retail
unit. We did hit Lenovo's own region-check red screen while messing with
stock ZUI firmware earlier, but that check lives in Lenovo's proprietary
firmware; the LineageOS-family `vendor_boot` (which AviumUI is built on)
is compiled from scratch and doesn't carry that code, and we never saw
anything like it again once on a LineageOS-based ROM.

#### Step by step

1. **Back up your data first.** The `Format data` step below wipes
   `/data` — installed apps, app data, logged-in accounts, all of it.
   Pull anything you care about from `/sdcard` with `adb pull` first.

2. Get the device into **fastboot (bootloader) mode**. If USB debugging
   is already on for the current OS:
   ```bash
   adb reboot bootloader
   ```
   Otherwise (e.g. fresh out of the box on stock ZUI), force it with a
   **Volume Down + Power** long-press combo. Confirm the PC sees it:
   ```bash
   fastboot devices
   ```
   You should see a serial number followed by `fastboot`.

3. Flash `recovery.img` to both A/B slots (this device has dedicated
   recovery partitions on each slot):
   ```bash
   fastboot flash recovery_a recovery.img
   fastboot flash recovery_b recovery.img
   ```

4. Boot into the recovery you just flashed:
   ```bash
   fastboot reboot recovery
   ```
   The tablet boots into the **AviumUI Recovery** menu (header reads
   `AviumUI Recovery Version 16.2.1`).

5. Using the volume keys to move and the power key to select:
   **Factory reset → Format data / factory reset**, confirm. You'll see
   scrolling text like `Wiping data... / Formatting /data... / Data wipe
   complete.` — that's expected, let it finish.

6. Back at the recovery main menu: **Apply update → Apply from ADB**.
   The screen will show something like
   `Now send the package you want to apply to the device with "adb sideload <filename>"...`
   — the device is now waiting to receive the package.

7. From the directory containing the zip, on your PC:
   ```bash
   adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
   ```
   The package is 2GB+, so this takes roughly 5–8 minutes depending on
   your cable/port. You'll see a scrolling percentage in the terminal.

8. **⚠️ A false alarm worth knowing about ahead of time:** after the
   transfer finishes, the recovery screen sometimes still shows
   **leftover text from a previous failed attempt**, e.g.
   `Install completed with status 3. Installation aborted.`
   This looks like the install just failed, but it's often just **stale
   text that never got redrawn**. Don't panic — go back into
   **Apply update → Apply from ADB** and see if it still looks like it's
   waiting, or just go ahead to step 9 and reboot: whether the system
   actually boots is the real test, far more reliable than that one line
   of leftover text.

9. Back at the main menu: **Reboot → System**. **First boot is noticeably
   slower than normal** (3–8 minutes of spinner/black screen is normal —
   it's doing first-run dex optimization and the A/B slot switch). Don't
   power off or force-reboot during this.

#### Troubleshooting

- **`adb devices`/`fastboot devices` shows nothing / `unauthorized`**:
  make sure the cable actually does data (not charge-only), try a
  different USB port (rear motherboard port over front-panel/hub), and
  check the tablet for a debugging authorization prompt.
- **Recovery menu is all in English and confusing**: volume keys move the
  cursor, power key selects — standard for most Android recoveries.
- **You see `Install completed with status 3`**: possibly the false alarm
  from step 8 above — re-enter Apply from ADB, or just reboot and check
  whether the system actually boots before assuming it failed.
- **Stuck on the boot logo for a long time after rebooting**: first boot
  genuinely takes longer than usual; give it 5–10 minutes before you start
  worrying, and only start troubleshooting past ~15 minutes.
- **Want to go back to your previous ROM**: if it's also a payload.bin
  sideload package, repeat steps 5–9 (no need to reflash recovery) and
  `adb sideload` your previous zip instead.

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

### Is this an officially supported device?

No, and it won't become one automatically. AviumUI has its own
[device/maintainer policy](https://github.com/AviumUI-Devices/official_devices/blob/main/README.md),
and `asphalt` isn't on that list. That means this build **won't receive
official OTA updates** — future versions will always be a manual download
from this repo's Releases page.

### Disclaimer

Unofficial, community-built, not affiliated with the AviumUI or LineageOS
projects, Lenovo, or lolipuru. Flashing custom firmware can brick your
device if something goes wrong partway (power loss, wrong partition,
etc.) — you're doing this at your own risk. Keep a copy of your stock
firmware / a working recovery image before you start.
