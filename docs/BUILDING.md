# 构建与复现

## 打包已验证的运行文件

仓库保留运行文件及已经签名的兼容 APK，各组件许可单独适用。默认生成不含外部固件、但可直接安装的公开模块：

```powershell
python package.py
```

输出 `dist/annibale-AirDrop-KernelSU-v0.3.6.zip`。即使本地已经暂存固件，默认也不会将它写入公开 ZIP。清单保留固件的固定哈希，安装前只允许该精确路径缺失，导入后与开机时都完整校验。

仅供本地使用的含固件包：`python package.py --firmware "D:\path\to\ezif.bin"`。输出名称含 `-with-firmware`，不要上传到公开仓库或 Release。`tools/prepare_firmware.py` 仍保留为旧的本地暂存工具，公开打包无需运行它。

## 编译兼容 APK

Windows：Python 3、JDK、Android SDK `platforms/android-36` 与 `build-tools/36.0.0`，设置 `ANDROID_HOME` 后运行：

```powershell
python app/build.py
python package.py
```

签名私钥不在仓库。没有本地密钥时，脚本会创建测试密钥；新签名不能直接覆盖不同签名的 APK。发布后续 APK 应沿用维护者自己的密钥。

## XosBridge / native runner

`runtime-reference/XosBridge.java` 为当前二进制的固定上游参考；使用 Android SDK javac/d8 构建。

原生 Rust/C 源码在 `upstream/houji/native/`，原始构建入口在 `upstream/houji/runtime/owly-xos/`。需要 Rust 的 `aarch64-linux-android` target、Android NDK 与对应 Linux/macOS 构建环境。此处保留上游相对布局和锁文件。

## K90 WLAN / Wonder / bridge

- `driver/k90-wlan/` 是 MiCode `annibale-w-oss`、提交 `55250c04057d25d3939ae8334cca6908cde01832` 合入 `driver/k90-wlan-current.patch` 的结果。
- 重新从该固定基线应用补丁可使用 `git apply --check` 后 `git apply`；不要向当前已经合入补丁的目录重复应用。
- ACK 基线与 Xiaomi 内核头文件的固定提交见 `upstream-lock.json`。
- `driver/build-reference/device.config` 是设备配置，`compiled.config` 是对应编译配置；符号及 ABI 校验脚本一并保留。
- `driver/houji-support/` 提供 bridge、Wonder 与构建使用的外部头文件。

`build-passthru.sh` / `build-stock.sh` 是原 Linux 构建布局的参考，使用 LLVM 18，假定 `/var/tmp/codex-k90` 下已有 `ack/`、`out-live/`、`micode/`、`houji/` 及 WLAN 目录。请按固定版本准备源码和本机生成的 Kbuild host tools；原构建客体的二进制缓存、整个 Linux 快照及分区镜像未放进仓库。

ABI 校验工具需要同机型原厂 `qca_cld3_kiwi_v2.ko`，按脚本说明放在参考工具旁。新 ko 必须核对导入 CRC、KCFI 类型 ID 与 module 入口/退出重定位。

本次发布保留了既有已验证无线二进制，并未在新电脑上从零重编内核无线载荷。因此，以上原生/内核重编路径属于复现资料，不能视为新产物已通过实机验证。
