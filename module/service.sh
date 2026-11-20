#!/system/bin/sh
moddir=${0%/*}
test ! -e "$moddir/disable" && test ! -e "$moddir/remove" || exit 0
root=/data/adb/annibale-xos
umask 077
mkdir -p "$root/state"
/data/adb/ksu/bin/busybox setsid /system/bin/sh "$moddir/bootstrap.sh" </dev/null >"$root/state/bootstrap.log" 2>&1 &
