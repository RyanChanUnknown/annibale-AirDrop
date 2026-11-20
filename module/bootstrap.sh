#!/system/bin/sh
set -eu
moddir=${0%/*}
root=/data/adb/annibale-xos
bb=/data/adb/ksu/bin/busybox
exec 6>"$root/state/bootstrap.lock"
"$bb" flock -n 6 6>&6 || exit 0
for i in $(seq 1 180); do test "$(getprop sys.boot_completed)" = 1 && break; sleep 1; done
test "$(getprop sys.boot_completed)" = 1
test ! -e "$moddir/disable" && test ! -e "$moddir/remove"
pid=$(cat "$root/state/supervisor.pid" 2>/dev/null || true)
case "$pid" in
 ''|*[!0-9]*) ;;
 *) if grep -zaq "$moddir/supervisor.sh" "/proc/$pid/cmdline" 2>/dev/null; then echo NATIVE_SUPERVISOR_ALREADY_RUNNING; exit 0; fi ;;
esac
. "$moddir/verify.sh"
if test -e "$root/state/saved.env"; then sh "$root/radio.sh" restore 6>&-; fi
rm -f "$root/state/boot-approved" "$root/state/page-active" "$root/background-receive.enabled"
if ! KSU=true BOOTMODE=true verify_package "$moddir" >"$root/state/boot-guard.log" 2>&1; then
 cat "$root/state/boot-guard.log"
 echo BOOT_GUARD_BLOCKED
 touch "$moddir/disable"
 reason=$(grep 'INSTALL_REJECTED:' "$root/state/boot-guard.log" | tail -n 1)
 notification_result=$(cmd notification post -t 'K90 AirDrop disabled after compatibility change' k90_airdrop_guard "$reason" 2>&1) || true
 exit 1
fi
cat "$root/state/boot-guard.log"
boot_id=$(cat /proc/sys/kernel/random/boot_id)
manifest=$(sha256sum "$moddir/files.sha256" | awk '{print $1}')
printf '%s:%s\n' "$boot_id" "$manifest" > "$root/state/boot-approved"
cmd statusbar add-tile org.annibale.xoscompat/.AirDropTile 2>&1 | cat
sh "$moddir/backend-action.sh" start 6>&-
echo NATIVE_SESSION_BRIDGE_READY
