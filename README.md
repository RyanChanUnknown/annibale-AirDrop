# REDMI K90 AirDrop

REDMI K90（`annibale`）原生小米互传 AirDrop 后端移植。通过 KernelSU / SukiSU 加载无线桥接，LSPosed 兼容原生小米互传；保留原 APK，不修改或重新签名小米互传。

当前版本：**模块 v0.3.5 / 兼容 APK v0.4.5**。

## 使用方式

- 从文件管理、相册等应用选择“分享至 Apple 设备”，原生会话自动启动无线后端。
- 控制中心“接收 Apple 文件”磁贴直接打开原生接收页面。
- 空闲桥接驻留时普通 Wi-Fi 可用；发送或接收期间 AirDrop 独占无线，退出后由原生会话释放并恢复 Wi-Fi。
- 已移除手动持续待收开关。修复重复进入分享页后无法再次发现设备的 mDNS 发送网卡绑定问题。
- 安装与每次开机均严格检查硬件、系统、内核、驱动、框架版本和文件哈希；不匹配即拒绝安装或停用模块。

## 已验证组合

| 项目 | 版本 |
|---|---|
| 设备 | REDMI K90 / annibale / 2510DRK44C |
| SoC / 无线 PCI | QTI SM8750 / sun / 17cb:1107 |
| 系统 | OS4.0.5.0.XPKCNXM，Android 17 / SDK 37 |
| 内核编译身份 | 6.6.118-android15-8-g0908354dac1b-ab16143355-4k，另核验完整哈希 |
| 小米互传 | 5.5.0_20261029_1004 / 50500，固定 APK 哈希 |
| SukiSU / ksud | 4.3.0-r2，uapi 6 |
| LSPosed | 2.2.1 / 7931 |
| Zygisk Next | 1.5.3 / 880 |
| SELinux | Enforcing |

完整约束见 [使用说明](docs/USAGE.zh-CN.txt) 和 [verify.sh](module/verify.sh)。其他系统、内核和机型尚未覆盖，检查失败时应重新适配。

## 下载与安装

[Releases](../../releases) 提供兼容 APK 与开放运行文件归档。**开放运行文件归档不是可直接刷入的 KernelSU 包。**

三星 EZIF 固件属于外部输入，按上游分发边界不放入公开仓库或 Release。自行准备下列 SHA-256 的固件后，即可在本地生成集成 APK 的完整模块：

```text
37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f
```

```powershell
python tools/prepare_firmware.py "D:\path\to\ezif.bin"
python package.py
```

在 KernelSU / SukiSU Ultra 管理器中安装 `dist/K90-AirDrop-KernelSU-v0.3.5-native.zip`，重启，在 LSPosed 激活“K90 AirDrop”，作用域仅选“小米互传”。无需单独给兼容 APK 授予 root。不支持 TWRP / Recovery 安装。

提供的独立 APK 用于更新或开发，它需要上述完整后端配合。

## 源码结构

| 目录 | 内容 |
|---|---|
| `app/` | LSPosed Wi-Fi 状态兼容、mDNS 出站网卡修复、接收页路由、快捷磁贴 |
| `module/` | KernelSU 校验、开机启动、监督进程、会话脚本及开放运行载荷 |
| `driver/k90-wlan/` | MiCode annibale 基线合入当前移植补丁的完整 WLAN 源码 |
| `driver/k90-wlan-current.patch` | 相对固定 MiCode 基线的移植补丁 |
| `driver/houji-support/` | 固定 Houji 版本的桥接、Wonder 和所需头文件 |
| `driver/build-reference/` | K90 配置、符号、原构建布局参考脚本与 ABI 校验工具 |
| `upstream/houji/native/` | 固定 Houji 版本的 owly、Android runner 和 wonder-init 源码 |
| `runtime-reference/` | 当前 XosBridge 参考源码 |
| `docs/` | 构建、适配及验证说明 |

参见 [构建说明](docs/BUILDING.md)、[验证记录](docs/VALIDATION.md)、[上游固定版本](upstream-lock.json)。本轮通过文件分享、图片分享、连续三轮重复搜索及用户在文件管理/相册中的复测。相同无线载荷此前已通过 131 B 和 16 MiB 双向回传及哈希核对；尚未做长期内存压力测试。

## 上游与授权

感谢 [ha0xin/houji-airdrop](https://github.com/ha0xin/houji-airdrop)、[AdenXie/pandora-airdrop](https://github.com/AdenXie/pandora-airdrop)、[MiCode](https://github.com/MiCode) 及 [t4t5/owly](https://github.com/t4t5/owly) 的实现与源码。

新增兼容及打包代码沿用 GPL-2.0-only；已有文件的版权与许可证声明优先。各组件边界及保留的许可证见 [NOTICE.md](NOTICE.md) 和 [LICENSES](LICENSES)。
