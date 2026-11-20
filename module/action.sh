#!/system/bin/sh
set -eu
moddir=${0%/*}
root=/data/adb/annibale-xos
expected="$(cat /proc/sys/kernel/random/boot_id):$(sha256sum "$moddir/files.sha256" | awk '{print $1}')"
test ! -e "$moddir/disable" && test ! -e "$moddir/remove" &&
test "$(cat "$root/state/boot-approved" 2>/dev/null || true)" = "$expected" || { echo ERROR=BOOT_GUARD_CLOSED; exit 1; }
result=$(am start -a android.intent.action.SEND -t "*/*" -n com.miui.mishare.connectivity/com.xiaomi.sharop.AirDropShareTrampolineActivity --ez org.annibale.xoscompat.OPEN_RECEIVE true 2>&1)
printf '%s\n' "$result"
