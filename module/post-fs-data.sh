#!/system/bin/sh
moddir=${0%/*}
root=/data/adb/annibale-xos
umask 077
mkdir -p "$root/state"
rm -f "$root/state/boot-approved" "$root/state/page-active"
. "$moddir/early-guard.sh"
if ! early_guard > "$root/state/early-boot-guard.log" 2>&1; then
 touch "$moddir/disable"
fi
