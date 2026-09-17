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

## 声明

苹果 EULA 只允许 macOS 装在苹果硬件上，本仓库仅供同型号机器折腾参考，请勿用于商业用途。
各 kext 与引导程序的版权归其原作者所有。刷机有风险，数据请自行备份。
