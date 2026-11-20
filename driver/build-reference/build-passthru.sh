#!/usr/bin/env bash
set -euo pipefail
root=/var/tmp/codex-k90
kernel=$root/ack
out=$root/out-live
driver=$root/wlan-passthru
wlan=$driver/qcacld-3.0
ipa=$root/houji/include/dataipa
mkdir -p "$root/logs"
test -e "$out/scripts/mod/modpost"
test -e "$out/include/generated/asm-offsets.h"
ln -sfn ../qca-wifi-host-cmn "$wlan/cmn"
make -C "$kernel" O="$out" ARCH=arm64 LLVM=-18 -k -j2 modules \
    M="$wlan" WLAN_ROOT="$wlan" WLAN_COMMON_ROOT=cmn \
    WLAN_COMMON_INC="$driver/qca-wifi-host-cmn" WLAN_FW_API="$driver/fw-api" \
    WLAN_PLATFORM_INC="$driver/platform/inc" DATA_IPA_INC="$ipa" DATA_IPA_UAPI_INC="$ipa/uapi" \
    CONFIG_QCA_CLD_WLAN=m MODNAME=qca_cld3_kiwi_v2 CHIP_NAME=kiwi_v2 WLAN_CTRL_NAME=wlan \
    WLAN_PROFILE=sun_gki_kiwi-v2 CONFIG_ARCH_SUN=y CONFIG_CNSS_OUT_OF_TREE=y \
    CONFIG_WLAN_TX_MON_2_0=y CONFIG_IPA_OUT_OF_TREE=y CONFIG_CNSS2=m CONFIG_CNSS2_QMI=y CONFIG_CNSS_UTILS=m \
    CONFIG_WCNSS_MEM_PRE_ALLOC=m CONFIG_CNSS_PLAT_IPC_QMI_SVC=m \
    HOUJI_WMI_C3_PROFILE=1 CONFIG_DRIVER_PASSTHRU_SESSION=y CONFIG_DRIVER_PASSTHRU_DP=y \
    CONFIG_DRIVER_PASSTHRU_OWNER=y CONFIG_DRIVER_PASSTHRU_MODE=y CONFIG_DRIVER_PASSTHRU_RUNTIME=y \
    KBUILD_EXTRA_SYMBOLS="$root/houji/bridge/Module.symvers" \
    KCFLAGS="-gline-tables-only -D__ANDROID_COMMON_KERNEL__ -DCONFIG_NL80211_TESTMODE=1 -DCONFIG_IPA3_MODULE=1 -DCONFIG_ARM_SMMU_MODULE=1 -DCONFIG_QCOM_IOMMU_UTIL_MODULE=1 -DCFG80211_MLO_KEY_OPERATION_SUPPORT=1 -DCFG80211_LINK_STA_PARAMS_PRESENT=1 -I$root/micode/include -I$root/houji/include/external -Wno-format -fstrict-flex-arrays=0" \
    > "$root/logs/wlan-passthru.log" 2>&1
