#!/system/bin/sh
fail() { echo "INSTALL_REJECTED: $*" >&2; return 1; }
require_equal() { test "$2" = "$3" || { fail "$1 expected=$2 actual=$3"; return 1; }; }
require_prop() { require_equal "$1" "$2" "$(getprop "$1")"; }
module_version() { sed -n 's/^versionCode=//p' "$1/module.prop" | head -n 1; }
check_hash() { echo "$1  $2" | sha256sum -c - || { fail "Stock file mismatch: $2"; return 1; }; }
verify_package() {
 package_dir=$1
 require_equal KSU true "${KSU:-false}" || return 1
 require_equal BOOTMODE true "${BOOTMODE:-false}" || return 1
 require_equal root 0 "$(id -u)" || return 1
 require_prop ro.product.device annibale || return 1
 require_prop ro.product.model 2510DRK44C || return 1
 require_prop ro.soc.manufacturer QTI || return 1
 require_prop ro.soc.model SM8750 || return 1
 require_prop ro.board.platform sun || return 1
 require_prop ro.hardware qcom || return 1
 require_prop ro.product.cpu.abi arm64-v8a || return 1
 require_prop ro.build.version.sdk 37 || return 1
 require_prop ro.build.version.incremental OS4.0.5.0.XPKCNXM || return 1
 require_prop ro.vendor.build.version.incremental OS4.0.5.0.XPKCN || return 1
 require_prop ro.build.fingerprint Redmi/annibale/annibale:17/CP2A.260605.016/OS4.0.5.0.XPKCNXM:user/release-keys || return 1
 grep -qF 'Linux version 6.6.118-android15-8-g0908354dac1b-ab16143355-4k ' /proc/version || { fail "Kernel ABI mismatch"; return 1; }
 check_hash 7cafb5c701086cc57855f3ba5502ac2fd2b1df22a6d167c331c8cd27216ad9c4 /proc/version || { fail "Kernel build identity changed"; return 1; }
 require_equal PCI_VENDOR 0x17cb "$(cat /sys/bus/pci/devices/0000:01:00.0/vendor 2>/dev/null)" || return 1
 require_equal PCI_DEVICE 0x1107 "$(cat /sys/bus/pci/devices/0000:01:00.0/device 2>/dev/null)" || return 1
 require_equal SELinux Enforcing "$(getenforce)" || return 1
 test -x /data/adb/ksu/bin/ksud && test -x /data/adb/ksu/bin/busybox || { fail "KernelSU tools missing"; return 1; }
 require_equal ksud 'ksud 4.3.0-r2 (uapi: 6)' "$(/data/adb/ksu/bin/ksud --version 2>&1)" || return 1
 for dependency in zygisk_lsposed zygisksu; do
  test -f "/data/adb/modules/$dependency/module.prop" && test ! -e "/data/adb/modules/$dependency/disable" && test ! -e "/data/adb/modules/$dependency/remove" || { fail "$dependency missing or disabled"; return 1; }
 done
 require_equal LSPosed_versionCode 7931 "$(module_version /data/adb/modules/zygisk_lsposed)" || return 1
 require_equal ZygiskNext_versionCode 880 "$(module_version /data/adb/modules/zygisksu)" || return 1
 pidof lspd >/dev/null || { fail "LSPosed framework is not running"; return 1; }
 for applet in flock nsenter setsid timeout; do
  /data/adb/ksu/bin/busybox --list | grep -qx "$applet" || { fail "busybox missing $applet"; return 1; }
 done
 test ! -e /data/adb/annibale-xos/state/saved.env && test ! -e /sys/class/net/xos0 &&
 test ! -e /sys/module/wonder && test ! -e /sys/module/houji_wonder_bridge || { fail "Turn AirDrop OFF and restore stock Wi-Fi before installing"; return 1; }
 exclusive=$(getprop sys.xos.exclusive)
 case "$exclusive" in ''|0) ;; *) fail "EXCLUSIVE expected=unset_or_0 actual=$exclusive"; return 1 ;; esac
 check_hash b1148d70312bca0da5a4544e23cb1a359a1ed42db41ca1f99ec51449ec8d5487 /vendor_dlkm/lib/modules/qca_cld3_kiwi_v2.ko || return 1
 check_hash 3044b0b5452b8b42405705121332ecb7f23ff1c63c519472d2f87f5abd92e359 /vendor/firmware_mnt/image/kiwi/amss20.bin || return 1
 check_hash 15fbb8dbfc784cd555c610835fea5eb8a2d229b35a69b68ba96e418e5edec966 /sys/module/qca_cld3_kiwi_v2/notes/.note.gnu.build-id || return 1
 native_path=$(pm path --user 0 com.miui.mishare.connectivity 2>&1) || { fail "MIShare missing"; return 1; }
 case "$native_path" in package:*/base.apk) native_path=${native_path#package:} ;; *) fail "Unsupported MIShare layout"; return 1 ;; esac
 check_hash 2af77172c368557f85df2286c955a9122de05210e9ccd340de2bf4d75c9209f8 "$native_path" || { fail "Requires MIShare 5.5.0_20261029_1004 (50500)"; return 1; }
 /data/adb/ksu/bin/ksud sepolicy check 'allow platform_app_36 default_android_service service_manager { find }' || { fail "Unsupported policy API"; return 1; }
 /data/adb/ksu/bin/ksud sepolicy check 'deny platform_app_36 default_android_service service_manager { find }' || { fail "Unsupported policy API"; return 1; }
 (cd "$package_dir" && sha256sum -c files.sha256) || { fail "Archive checksum mismatch"; return 1; }
 echo COMPATIBILITY_PASS
}
