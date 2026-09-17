# ASUS TUF Gaming A15 FA506IV —— 黑苹果 OpenCore EFI

针对 **ASUS TUF Gaming A15 FA506IV**（Ryzen 7 4800H + RTX 2060 + 16GB）定制的
OpenCore 引导配置，目标是 macOS Sonoma 14.x。

- 引导：OpenCore 1.0.7 RELEASE（已通过官方 `ocvalidate`：No issues found）
- 目标系统：macOS Sonoma 14.4 及以上（14.4 起 Intel 网卡驱动才可用）
- 平台机型：`MacBookPro16,2`（**SMBIOS 三码已清空，请自行生成，见下文**）

完整的装机步骤、排错对照表和已知限制请看 **[使用说明.md](使用说明.md)**。

---

## 硬件支持情况

| 部件 | 型号 | macOS 情况 |
| --- | --- | --- |
| CPU | Ryzen 7 4800H | 可用，AMD 内核补丁 + `ProvideCurrentCpuInfo` |
| 核显 | Radeon Vega (Renoir) | 可用，NootedRed 驱动，带硬件加速 |
| 独显 | NVIDIA RTX 2060 | **无驱动，永久不可用** |
| 有线网卡 | Realtek RTL8168/8111 | 可用，已设为内建 |
| 无线网卡 | Intel AX210 | 可用（AirportItlwm），6GHz 不可用 |
| 蓝牙 | Intel AX210 | 可用 |
| 声卡 | Realtek ALC256 | 可用，`alcid=23` |
| 触控板 | I2C HID | 基本可用，多指手势可能不全 |
| 键盘 | PS/2 | 可用，Fn 亮度/音量键可用 |
| 硬盘 | KIOXIA NVMe | 可用，附 NVMeFix |

---

## 目录结构

```
.
├─ EFI-Final/EFI/          ← 装好系统后日常使用（NootedRed 核显加速）
├─ EFI-Install/EFI/        ← 安装 / 大版本升级 macOS 时使用（WhateverGreen 代替 NootedRed）
├─ 修复配置/               ← 4 套备用 config.plist，按现象替换使用
│   ├─ 1-关闭安全启动模拟/
│   ├─ 2-再加官方AMD引导参数/
│   ├─ 3-老固件内存组合/
│   └─ 4-蓝牙排查-暂时停用USB端口映射/
├─ 可选驱动/itlwm.kext      ← 只有装 macOS 15 (Sequoia) 时才需要
├─ 小工具/修复Windows时间.ps1
└─ 使用说明.md
```

两个 EFI 的差别只有一处：`Kernel → Add` 里 `NootedRed.kext` 与 `WhateverGreen.kext` 的开关。
安装阶段用 NootedRed 容易黑屏，所以先用 WhateverGreen 把系统装进硬盘，装完再换成 EFI-Final
启用核显加速；两边都准备好了，装的时候哪个能亮就用哪个。

---

## 安装盘里没有的恢复镜像

本仓库**不包含** `com.apple.recovery.boot/`（macOS Sonoma 恢复镜像，753MB）。
原因有两个：单文件超过 GitHub 的 100MB 限制，而且它是苹果的版权文件，不宜公开分发。

在 Windows 上用 OpenCore 官方脚本自行下载即可（需要 Python）：

```
python3 macrecovery.py -b Mac-7BA5B2D9E42DDD94 -m 00000000000000000 download
```

把下载得到的 `com.apple.recovery.boot` 文件夹放到 U 盘根目录，和 `EFI` 文件夹并排，
然后按 [使用说明.md](使用说明.md) 第四、五节操作。

---

## 重要：使用前必须生成自己的 SMBIOS

发布版的 `config.plist` 里 `PlatformInfo → Generic` 的
`SystemSerialNumber` / `MLB` / `SystemUUID` / `ROM` 已全部清空或置零，
**直接使用将无法登录 iCloud / iMessage**。请先用自己的三码：

1. 下载 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS)；
2. 运行 `python3 GenSMBIOS.py`，依次选 `2`（下载 MacSerial）、`3`（生成 SMBIOS）；
3. 机型填 `MacBookPro16,2`，把输出的 Serial / Board Serial / SmUUID 填入
   `PlatformInfo → Generic`，`ROM` 填本机有线网卡 MAC 地址的十六进制字节。

改 config.plist 建议用 [ProperTree](https://github.com/corpnewt/ProperTree)，
不要用 OpenCore Configurator 之类的工具，容易写坏文件。

---

## 把核显显存（UMA Frame Buffer）改成 4GB

macOS 下核显能用多少显存，是由 BIOS 里的 **UMA Frame Buffer Size** 决定的。华硕的 BIOS 界面
**不暴露这一项**，默认可能只有 512MB，NootedRed 就会出现「显示器 8MB」、界面卡顿、花屏之类的问题。

用 [DavidS95/Smokeless_UMAF](https://github.com/DavidS95/Smokeless_UMAF) 可以在**不刷 BIOS** 的前提下
读取出 AMD CBS 隐藏菜单，把显存调到 4GB，核显会明显更流畅。

### 操作步骤

1. 准备一个 **FAT32** 格式的 U 盘（≥1GB 即可，里面数据会被清空）。
2. 在项目页面下载 [`UniversalAMDFormBrowser.zip`](https://github.com/DavidS95/Smokeless_UMAF/raw/main/UniversalAMDFormBrowser.zip)
   （正式版，约 150KB；仓库里另有 `UMAF_BETA.zip` 测试版，建议先用正式版）。
3. 把压缩包**解压到 U 盘根目录**（解压出来是个 `Boot` 文件夹，直接放在根目录）。
4. 插上 U 盘重启，开机连按 **Esc**（或 F8）调出启动菜单，选 **UEFI: 你的U盘**。
5. 进入工具界面后依次点：
   **Device Manager** → **AMD CBS**（部分机器在 AMD PBS 里）
   → **NBIO Common Options** → **GFX Configuration**
6. **关键一步**：在 `GFX Configuration` 里把 **iGPU Configuration** 从 `Auto` 改成 **`UMA_SPECIFIED`**。
   默认的 `Auto` 会把它藏起来，改成 `UMA_SPECIFIED` 之后，下面才会出现
   **`UMA Frame Buffer Size`** 这一项。
7. 把 **UMA Frame Buffer Size** 选成 **4G**（列表通常是 64M / 128M / 256M / 512M / 1G / 2G / 4G / 8G）。
   改之前先把原始值记下来，方便恢复。
8. 按 **Esc** 一路退出，出现保存提示时选 **保存 / Yes**，然后重启。
9. 验证：macOS「关于本机 → 系统报告 → 图形卡」里的显存应接近 4GB；Windows 可在任务管理器
   → 性能 → GPU 里查看。

### 注意

- **这是真实的 BIOS 设置，改错可能开不了机。** 只动 `iGPU Configuration` 和
  `UMA Frame Buffer Size` 这两项，不要碰 `Curve Optimizer`、`P0State Vid` 之类
  ——项目作者把这两项明确列为危险设置。
  万一改坏：先试清 BIOS（断电 / CLR_CMOS），严重时只能重新刷 BIOS。
- 显存是从内存里划走的：设成 4GB，系统可用内存就少 4GB（16GB 的机器剩 12GB 左右）。
  如果内存只有 8GB，建议设 2G。
- 个别机器的 BIOS 会在下次开机把这项重置为默认，装完系统后回头确认一次。
- 如果在 `GFX Configuration` 里找不到 `iGPU Configuration`，退回上一层 `NBIO Common Options`
  再翻一遍其他子项；不同 BIOS 版本的层级摆放会有差别。
- 该工具原始作者是 **SmokelessCPU**，DavidS95 的仓库是备份仓库；使用风险自负。

---

## 已知限制

1. RTX 2060 永远用不了；HDMI 走核显可用，Type-C/DP 走独显所以不可用。
2. 独显一直通电（无驱动、无法休眠），续航比 Windows 短，机器也可能略热。
3. 睡眠：同型号记录是「能睡，偶尔立即唤醒」。
4. Wi-Fi 6GHz 不可用（AX210 的 6E 只能当 2.4/5G 用）。
5. NootedRed 在 Sonoma 上有已知偶发卡顿/崩溃。

---

## 来源与致谢

- OpenCore 1.0.7、Lilu、VirtualSMC、AppleALC、WhateverGreen、RestrictEvents、NVMeFix、
  VoodooPS2、VoodooI2C：acidanthera / VoodooI2C 官方发布
- 核显驱动 NootedRed 0.8.10：ChefKissInc 官方发布（原样使用官方二进制）
- AMD 内核补丁：AMD-OSX/AMD_Vanilla（按 4800H 的 8 核修改 cpuid 常量）
- 无线/蓝牙：OpenIntelWireless（itlwm、IntelBluetoothFirmware）
- 有线网卡：Mieze/RTL8111_driver_for_OS_X
- ACPI 与 USB 端口映射：参考同型号开源项目 Lyianu/FA506IV-OpenCore，并按 OpenCore 1.0.7 重新整理
- 显存解锁（UMA Frame Buffer Size）：[DavidS95/Smokeless_UMAF](https://github.com/DavidS95/Smokeless_UMAF)（原项目 SmokelessCPU）

## 声明

苹果 EULA 只允许 macOS 装在苹果硬件上，本仓库仅供同型号机器折腾参考，请勿用于商业用途。
各 kext 与引导程序的版权归其原作者所有。刷机有风险，数据请自行备份。
