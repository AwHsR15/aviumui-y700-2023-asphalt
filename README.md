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
LineageOS 没有区别。下面写得比较啰嗦,是想把每一步"应该看到什么"都说
清楚,免得刷到一半心里没底。

#### 刷机前需要确认

- [ ] **bootloader 已解锁**
- [ ] **设备当前正跑着某个基于 LineageOS 23.2 的系统**(原版 LineageOS
      23.2 或更早的 AviumUI 都行),这样它的 Recovery 才能识别并接受这个
      包。如果你现在还是联想原厂 ZUI 系统,得先解锁 bootloader、刷上
      LineageOS 23.2(具体做法参考 lolipuru 的设备树仓库或相关论坛帖),
      走完这一步之后再回来刷本仓库这个包
- [ ] 电脑上装好了 **adb 和 fastboot**(Android SDK Platform Tools),
      命令行里能正常识别
- [ ] **USB 数据线插在平板长边那个接口**(短边那个口不能用来传数据 /
      刷机,插错了 `adb devices` 会看不到设备)
- [ ] 电量至少 50%
- [ ] 刷机包已经按上面的方法合并好、`SHA256SUMS.txt` 校验通过

关于机型:不管你这台是**国行还是全球版**,理论上都能刷 —— 我们自己那台
就是国行渠道买的二手机。之前折腾原厂 ZUI 系统时确实撞过联想自己加的
"区域校验"红字报错,但那是联想 ZUI 系统固件里专有的检查逻辑;LineageOS
系(以及基于它的 AviumUI)用的 `vendor_boot` 是完全独立编译出来的开源版本,
不含联想那段专有代码,实测流程里也确实再没遇到过这类问题。

#### 详细步骤

1. **先备份数据**。下面第 3 步的 `Format data` 会清空 `/data` 分区 ——
   已安装的应用、应用内部数据、账号登录状态等全部清空。`/sdcard` 里的
   照片、下载文件等如果重要,建议先用 `adb pull` 导出一份。

2. 电脑连好数据线后,先确认能识别到设备:
   ```bash
   adb devices
   ```
   应该能看到一行"序列号 + device"。如果显示 `unauthorized`,看一眼平板
   屏幕,把弹出的 USB 调试授权对话框点"允许"。

3. 让设备重启进 Recovery:
   ```bash
   adb reboot recovery
   ```
   平板会重启,进入一个 **LineageOS 风格的 Recovery 菜单**(黑底或白底,
   顶部会写着当前系统的名字和版本号,比如 `Version 23.2` 或者
   `AviumUI Recovery Version 16.2.1`)。

4. 在 Recovery 菜单里,用**音量键**上下移动光标、**电源键**确认,依次
   选择:**Factory reset → Format data / factory reset**,确认执行。
   屏幕会滚动出现类似
   `Wiping data... / Formatting /data... / Data wipe complete.`
   的文字,这是正常的,等它跑完。

5. 返回 Recovery 主菜单,选择:**Apply update → Apply from ADB**。
   屏幕会显示类似
   `Now send the package you want to apply to the device with "adb sideload <filename>"...`
   —— 这说明设备已经在等待接收了。

6. 回到电脑,在刷机包所在目录下执行:
   ```bash
   adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
   ```
   这个包 2GB+,传输大概要 5–8 分钟(具体看你的数据线和 USB 口速度),
   命令行会滚动显示百分比进度,类似 `serving: '...' (~50%)`。

7. **⚠️ 有一个很容易让人虚惊一场的地方**:传输结束后,Recovery 屏幕上
   有时会**残留显示上一次尝试失败时留下的旧文字**,比如
   `Install completed with status 3. Installation aborted.`
   看着像是这次也失败了,但其实**这只是屏幕没刷新干净,显示的是过时
   信息**。判断刷机到底成没成功,别看这行字,要看 **Recovery 菜单本身
   有没有变化** —— 如果刷成功了,整个 Recovery 的主题、logo 都会变成
   "AviumUI Recovery",顶部版本号会显示新的 `Version 16.2.1`。只要
   看到这个变化,就说明其实已经装好了,可以放心继续往下刷。

8. 回到 Recovery 主菜单,选择 **Reboot → System**,进入新系统。**首次
   开机会明显比平时慢很多**(3–8 分钟内的转圈、黑屏都是正常现象,是在
   做首次的 dex 优化和 A/B 分区切换),这个阶段千万别断电或强制重启。

#### 常见问题排查

- **`adb devices` 看不到设备,或显示 `unauthorized`**:先确认数据线支持
  数据传输(不是纯充电线),换个 USB 口试试(优先主板后置接口,避免
  用前置面板或 USB Hub),然后看平板屏幕上是否有调试授权弹窗需要确认。
- **Recovery 里的英文菜单看不太懂**:标准操作方式是音量键上下移动光标、
  电源键确认,跟大多数 Android 官方 Recovery 一样。
- **出现 `Install completed with status 3`**:大概率是第 7 步说的假警报,
  别慌,先看 Recovery 的主题 / 版本号是不是已经变成新系统的样子。
- **重启后卡在 logo 界面很久不动**:首次开机确实会比平时明显久,耐心
  等 5–10 分钟;如果超过 15 分钟屏幕还是一动不动,再考虑排查问题。
- **想刷回原来的系统**:重新走一遍上面的流程,把 `adb sideload` 后面
  换成你原来的那个刷机包文件名即可,和刷新包的操作完全一样。

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

### 这个能提交给 AviumUI 官方吗?

查了一下 AviumUI 官方公开的
[设备与维护者准入政策](https://github.com/AviumUI-Devices/official_devices/blob/main/README.md),
老实说 —— **现在还不够格,但路是通的**,把关键几条摘出来:

- **必须实际持有并长期使用这台设备**(这条我们满足)
- **要有基础的代码阅读和自主排查问题的能力**(这次整个折腾过程也算是
  证明了)
- **必须先有一段"非官方维护期"**,原文写得很直白:「只交一次构建就马上
  申请转正,不算是充分的维护经验」("Submitting a single build and
  immediately applying for official status will not be considered
  sufficient maintenance experience")—— 也就是说,**这个仓库现在这样
  发一次版是不够的**,得持续跟进维护一段时间(修 bug、跟新版本、保持
  更新)才有资格申请。
- 一旦被正式收编,**对应的设备树仓库必须迁移托管到 AviumUI 官方的
  GitHub 组织下**。但设备树和内核是 **lolipuru** 的心血,这件事怎么都
  绕不开要先跟他打招呼、达成一致 —— 不会绕过原作者自己去申请。
- 官方沟通(commit message、代码注释、技术讨论)**必须用英文**。
- 官方正式版**不能预装 Magisk / KernelSU 等 root 方案**,这点本仓库
  发的刷机包本来就是纯净的(Magisk 是可选的额外文件,不在 ROM 包里)。

**现实的下一步**:先在这个仓库里持续发布 + 维护一段时间(这本身就是政策
要求的"非官方维护期"),同时找机会联系一下 lolipuru,看他对设备树"官方
收编"这件事是什么态度、要不要一起推进。真要往前走的话,联系渠道是
AviumUI 的 [Telegram 群](https://t.me/AviumUI) 或者他们的
[GitHub 组织](https://github.com/AviumUI)。

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

Standard LineageOS-recovery-based A/B sideload flow. Written out in more
detail than strictly necessary, so you know what you should be seeing at
each step instead of just guessing whether it worked.

#### Before you start

- [ ] **Unlocked bootloader**
- [ ] **Device is already running something LineageOS 23.2-based** (stock
      LineageOS 23.2 or an earlier AviumUI build both work) so its recovery
      will actually accept this package. If you're still on stock ZUI,
      unlock the bootloader and flash LineageOS 23.2 first (see lolipuru's
      device tree repo / thread), then come back to this.
- [ ] **adb and fastboot installed** (Android SDK Platform Tools) and
      working from your PC's command line
- [ ] **USB cable plugged into the port on the long edge of the tablet**
      (the short-edge port won't do data transfer / flashing — if
      `adb devices` shows nothing, this is the first thing to check)
- [ ] Battery at least 50%
- [ ] The zip is reassembled and `SHA256SUMS.txt` checks out

On region: this should work regardless of whether your unit is a China
retail (国行) or global (ROW) unit — ours is a secondhand China-retail
unit. We did hit Lenovo's own region-check red screen while messing with
stock ZUI firmware earlier, but that check lives in Lenovo's proprietary
firmware; the LineageOS-family `vendor_boot` (which AviumUI is built on)
is compiled from scratch and doesn't carry that code, and we never saw
anything like it again once on a LineageOS-based ROM.

#### Step by step

1. **Back up your data first.** Step 3 below (`Format data`) wipes
   `/data` — installed apps, app data, logged-in accounts, all of it.
   Pull anything you care about from `/sdcard` with `adb pull` first.

2. With the cable connected, confirm the device shows up:
   ```bash
   adb devices
   ```
   You should see a serial number followed by `device`. If it says
   `unauthorized`, check the tablet screen for a USB debugging
   authorization prompt and accept it.

3. Reboot into recovery:
   ```bash
   adb reboot recovery
   ```
   The tablet reboots into a LineageOS-style recovery menu (black or white
   background, with the current ROM name/version at the top, e.g.
   `Version 23.2` or `AviumUI Recovery Version 16.2.1`).

4. Using the volume keys to move and the power key to select:
   **Factory reset → Format data / factory reset**, confirm. You'll see
   scrolling text like `Wiping data... / Formatting /data... / Data wipe
   complete.` — that's expected, let it finish.

5. Back at the recovery main menu: **Apply update → Apply from ADB**.
   The screen will show something like
   `Now send the package you want to apply to the device with "adb sideload <filename>"...`
   — the device is now waiting to receive the package.

6. From the directory containing the zip, on your PC:
   ```bash
   adb sideload AviumUI-16.2.1-asphalt-20260802-Unofficial-GMS.zip
   ```
   The package is 2GB+, so this takes roughly 5–8 minutes depending on
   your cable/port. You'll see a scrolling percentage in the terminal.

7. **⚠️ A false alarm worth knowing about ahead of time:** after the
   transfer finishes, the recovery screen sometimes still shows
   **leftover text from a previous failed attempt**, e.g.
   `Install completed with status 3. Installation aborted.`
   This looks like the install just failed, but it's often just **stale
   text that never got redrawn**. Don't trust that line — check whether
   the **recovery UI itself has changed**: if the flash actually
   succeeded, the whole recovery theme/logo changes to "AviumUI Recovery"
   and the version at the top updates to `Version 16.2.1`. If you see
   that, it worked, and you can safely continue.

8. Back at the main menu: **Reboot → System**. **First boot is noticeably
   slower than normal** (3–8 minutes of spinner/black screen is normal —
   it's doing first-run dex optimization and the A/B slot switch). Don't
   power off or force-reboot during this.

#### Troubleshooting

- **`adb devices` shows nothing / `unauthorized`**: make sure the cable
  actually does data (not charge-only), try a different USB port
  (rear motherboard port over front-panel/hub), and check the tablet for
  a debugging authorization prompt.
- **Recovery menu is all in English and confusing**: volume keys move the
  cursor, power key selects — standard for most Android recoveries.
- **You see `Install completed with status 3`**: probably the false alarm
  from step 7 above — check the recovery theme/version before assuming
  it failed.
- **Stuck on the boot logo for a long time after rebooting**: first boot
  genuinely takes longer than usual; give it 5–10 minutes before you start
  worrying, and only start troubleshooting past ~15 minutes.
- **Want to go back to your previous ROM**: repeat the same flow and
  `adb sideload` your previous zip instead — identical process either way.

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

### Can this be submitted to AviumUI officially?

Checked AviumUI's public
[Official Device and Maintainer Policy](https://github.com/AviumUI-Devices/official_devices/blob/main/README.md).
Short answer: **not yet, but there's a real path.** Key points from that
policy:

- **Maintainers must physically own and actively use the device** (true
  for us)
- **Basic code-reading and self-debugging ability** required (this whole
  build/debug process is decent evidence of that)
- **Prior unofficial maintenance experience is required.** Quoting
  directly: "Submitting a single build and immediately applying for
  official status will not be considered sufficient maintenance
  experience." So this repo, as a one-off release, isn't enough on its
  own — it needs to be maintained for a while (bugfixes, following new
  releases, staying current) before applying makes sense.
- **Once a device is approved, its device tree repo must be hosted under
  the official AviumUI GitHub organization.** The device tree and kernel
  here are [lolipuru](https://github.com/lolipuru)'s work, so this isn't
  something to pursue without looping them in first — it's their call,
  not something to route around them for.
- Official commit messages/comments/discussion **must be in English**.
- Official release builds **must not ship with Magisk/KernelSU
  pre-integrated**, which this repo's ROM zip already satisfies (Magisk
  is only an optional separate asset, not baked into the ROM).

**Practical next step:** keep publishing and maintaining builds here for a
while (which is effectively the "unofficial maintenance period" the
policy asks for), and separately reach out to lolipuru about whether they
want to pursue official adoption of the device tree. If/when that's
worth pursuing further, the contact points are AviumUI's
[Telegram](https://t.me/AviumUI) or their
[GitHub org](https://github.com/AviumUI).

### Disclaimer

Unofficial, community-built, not affiliated with the AviumUI or LineageOS
projects, Lenovo, or lolipuru. Flashing custom firmware can brick your
device if something goes wrong partway (power loss, wrong partition,
etc.) — you're doing this at your own risk. Keep a copy of your stock
firmware / a working recovery image before you start.
