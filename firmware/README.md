# S24 Ultra EZIF 固件获取

公开 KernelSU ZIP 已集成兼容 APK，但不附带三星固件。安装前把正确文件放到手机下载目录；升级可复用旧模块的匹配文件。

本机曾对上游下载器的 Python 缓存产生 `Backdoor/Meterpreter.ea` 告警，尚无厂商结论。源码来源核对、审查范围与限制见 [告警记录](../docs/DOWNLOADER-REVIEW.md)；不要关闭安全防护或忽略告警。

## 下载链接与来源

- [v0.3.6 固件获取工具 ZIP](https://github.com/RyanChanUnknown/annibale-AirDrop/releases/download/v0.3.6/annibale-AirDrop-firmware-tools-v0.3.6.zip)：解压后运行下方命令。
- [获取脚本源码](https://github.com/RyanChanUnknown/annibale-AirDrop/blob/main/firmware/get_amss20.py) / [直接保存脚本](https://raw.githubusercontent.com/RyanChanUnknown/annibale-AirDrop/main/firmware/get_amss20.py) / [位置索引 JSON](https://raw.githubusercontent.com/RyanChanUnknown/annibale-AirDrop/main/firmware/recipe/S928BXXU6EZIF.json)。单独保存脚本时把索引放进脚本旁的 `recipe/` 目录，建议直接使用工具 ZIP。
- [三星 FUS 下载服务](https://cloud-neofussvr.samsungmobile.com/)：协议服务入口，最终的授权下载地址由脚本协商取得，不是可在浏览器直接下载 bin 的页面。
- [模块下载页](https://github.com/RyanChanUnknown/annibale-AirDrop/releases/latest) 与 [精确固件版本、路径和 SHA-256](../docs/FIRMWARE-LICENSING.md#当前外部输入)。

## 自动获取并推送

电脑安装 Python 3.8 或更高版本，需要推送时另装 Android platform-tools，并开启手机 USB 调试。在仓库根目录或 Release 工具压缩包根目录运行：

```powershell
python firmware/get_amss20.py --push
```

脚本通过三星官方 FUS 服务读取固定 S24 Ultra / SM-S928B、FWD、S928BXXU6EZIF 包中的相应片段，在电脑本地解密、解压、还原，再核对固定 SHA-256；不会从本项目下载固件。位置文件只含偏移、长度和校验信息。

省略 `--push` 只保存到电脑当前目录的 `s24u-amss20.bin`，可手动复制到手机 `/sdcard/Download/s24u-amss20.bin`。多个 ADB 设备时用 `--serial <设备序列号>`。运行中不需要关闭手机 Wi-Fi 或启动无线后端。

Python 标准库即可运行；安装 pycryptodome(x) 或 cryptography 后可加速 AES，未安装时使用内置实现。本版实际只读取 **5,293,504 字节，约 5.05 MiB**，还原 6,447,168 字节 bin，已从官方服务器回取并核对完整哈希，见 [验证记录](../docs/VALIDATION.md)。

## 已有匹配文件

```powershell
python firmware/get_amss20.py --file "D:\path\to\ezif.bin" --push
```

哈希不匹配会拒绝输出和推送。`--file` 不访问服务器。文件名相同不代表版本相同，不能使用 Pandora 的 S26 固件替代本项目的 S24 文件。

要求的 SHA-256：

```text
37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f
```

## 安装与升级

退出 Apple 互传并等待普通 Wi-Fi 恢复，然后在 KernelSU / SukiSU 管理器刷入公开 ZIP。安装器依次检查兼容性、静态文件、外部固件和完整清单，最后才安装 APK。成功后重启，并在 LSPosed 激活 K90 AirDrop，作用域仅选小米互传。

导入顺序为已安装模块、已部署运行目录、下载目录的 `s24u-amss20.bin` 或 `ezif.bin`，只复制哈希匹配者；不删除用户提供的源文件。外部来源均不匹配时安装失败。私有含固件包内的文件错误时直接失败，不用外部文件掩盖错误包。

`--module <公开模块.zip>` 可在电脑另生成 `-with-firmware.zip` 供本地安装；不要上传这种包。默认 `python package.py` 无论本地是否暂存固件都生成无固件公开包。

三星可能撤下旧版本或改变包布局。工具会因版本/大小/哈希不符停止，不会自动改用新固件。维护者需为新包重新生成位置索引并验证；普通用户也可自行合法取得上述精确哈希的文件。授权边界见 [说明](../docs/FIRMWARE-LICENSING.md)。

## 工具来源

`get_amss20.py` 与维护者索引生成器基于 AdenXie/pandora-airdrop 提交 `6e7b13bf7e6a866e9cee5f6575b56da023a2314a` 的独立 GPL-2.0-only 实现适配。K90 更换为 S24 EZIF 的固定身份和索引，增加本地文件、ADB 序列号和原子写入支持。未采用 S26 的位置索引或固件。

维护者可在 Linux 安装 `lz4` Python 包和 erofs-utils 后，先运行 `python firmware/make_recipe.py scan --work <工作目录>`，再运行 `python firmware/make_recipe.py build --work <工作目录> -o firmware/recipe/S928BXXU6EZIF.json`。首次扫描需要读取 AP 的大量数据和数 GB 空间，普通用户无需执行。位置索引只有经官方服务器回取、最终哈希匹配后才可发布；切勿提交扫描产生的 vendor 镜像、加密包或中间数据。
