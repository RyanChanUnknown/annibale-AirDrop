# annibale-AirDrop

REDMI K90（`annibale`）原生小米互传 AirDrop 后端移植。通过 KernelSU / SukiSU 加载无线桥接，LSPosed 兼容原生小米互传；保留原 APK，不修改或重新签名小米互传。

当前版本：**模块 v0.3.6 / 兼容 APK v0.4.5**。

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

[Releases](../../releases) 提供 **可直接交给 KernelSU 安装的 ZIP，已集成兼容 APK，不含外部固件**。无需自己打包。

1. 下载并解压 [固件获取工具 ZIP](https://github.com/RyanChanUnknown/annibale-AirDrop/releases/download/v0.3.6/annibale-AirDrop-firmware-tools-v0.3.6.zip)，在电脑运行以下命令，从三星官方服务器获取并校验 S24 Ultra EZIF 固件，再推送到手机下载目录：

```powershell
python firmware/get_amss20.py --push
```

2. 退出 Apple 互传页面、等待原厂 Wi-Fi 恢复，在 KernelSU / SukiSU Ultra 管理器安装 `annibale-AirDrop-KernelSU-v0.3.6.zip`。安装器检查硬件和版本，导入固件并自动安装 APK。升级时自动复用旧模块中哈希匹配的固件。
3. 重启，在 LSPosed 激活“K90 AirDrop”，作用域仅选“小米互传”。无需单独给兼容 APK 授予 root。不支持 TWRP / Recovery 安装。

也可以自行准备匹配文件，命名 `s24u-amss20.bin` 放到手机 `/sdcard/Download/`。固定 SHA-256：

```text
37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f
```

获取细节、已有文件校验、多个 ADB 设备与官方旧包失效的处理见 [固件说明](firmware/README.md)。公开包不提供三星 bin；分发边界见 [固件授权说明](docs/FIRMWARE-LICENSING.md)。独立 APK 用于更新或开发，需要模块后端配合。

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
| `firmware/` | 官方服务器获取工具及仅含位置参数的固件索引 |

参见 [构建说明](docs/BUILDING.md)、[验证记录](docs/VALIDATION.md)、[上游固定版本](upstream-lock.json)。本轮通过文件分享、图片分享、连续三轮重复搜索及用户在文件管理/相册中的复测。相同无线载荷此前已通过 131 B 和 16 MiB 双向回传及哈希核对；尚未做长期内存压力测试。

## 移植建议

[移植记录与建议](docs/PORTING.md) 记录了 Binder/SELinux 文件描述符、flock 继承、ABI 对齐、分享会话生命周期、未导出接收页和重复发现的 mDNS 出站网卡问题，并区分实测结论与后续建议。继续移植时，优先保证失败恢复，再扩展机型、共存和省电功能。

## 上游与授权

感谢 [ha0xin/houji-airdrop](https://github.com/ha0xin/houji-airdrop)、[AdenXie/pandora-airdrop](https://github.com/AdenXie/pandora-airdrop)、[MiCode](https://github.com/MiCode) 及 [t4t5/owly](https://github.com/t4t5/owly) 的实现与源码。

新增兼容及打包代码沿用 GPL-2.0-only；已有文件的版权与许可证声明优先。各组件边界及保留的许可证见 [NOTICE.md](NOTICE.md) 和 [LICENSES](LICENSES)。

下载annibale开头的文件就行。K90开头的是老文件，忘了删
