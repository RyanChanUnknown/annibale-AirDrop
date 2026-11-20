#!/system/bin/sh
set -eu
moddir=${0%/*}
root=/data/adb/annibale-xos
bb=/data/adb/ksu/bin/busybox
test "$(getprop ro.product.device)" = annibale
test "$(getprop ro.build.version.incremental)" = OS4.0.5.0.XPKCNXM
grep -qF 'Linux version 6.6.118-android15-8-g0908354dac1b-ab16143355-4k' /proc/version
operation=${1:-start}
case "$operation" in start|stop) ;; *) echo ERROR=INVALID_OPERATION; exit 2 ;; esac
umask 077
mkdir -p "$root/state" "$root/firmware" "$root/radio"
exec 8>"$root/state/action.lock"
"$bb" flock -n 8 8>&8
pid=$(cat "$root/state/supervisor.pid" 2>/dev/null || true)
case "$pid" in
 ''|*[!0-9]*) ;;
 *)
  if grep -zaq "/supervisor.sh" "/proc/$pid/cmdline" 2>/dev/null; then
   if test "$operation" = start; then echo NATIVE_SUPERVISOR_ALREADY_RUNNING; exit 0; fi
   touch "$root/state/stop-supervisor"
   for i in $(seq 1 30); do
    if ! kill -0 "$pid" 2>/dev/null; then
     cat "$root/state/status"
     if test -r "$root/state/supervisor.exit"; then
      exit "$(cat "$root/state/supervisor.exit")"
     fi
     exit 1
    fi
    sleep 1
   done
   echo "Restore is still in progress. See $root/state/supervisor.log."
   exit 1
  fi ;;
esac
if test "$operation" = stop; then exit 0; fi
test ! -e "$moddir/disable" && test ! -e "$moddir/remove"
expected="$(cat /proc/sys/kernel/random/boot_id):$(sha256sum "$moddir/files.sha256" | awk '{print $1}')"
test "$(cat "$root/state/boot-approved" 2>/dev/null || true)" = "$expected" || { echo ERROR=BOOT_GUARD_CLOSED; exit 1; }
test ! -e "$root/state/saved.env" || { echo 'Previous session needs restoration.'; exit 1; }
(cd "$moddir/payload" && sha256sum -c installation.sha256)
for f in radio.sh xos-bridge.zip owly-xosd wonder-init qca_cld3_kiwi_v2.ko firmware/ezif.bin radio/houji_wonder_bridge.ko radio/wonder.ko installation.sha256; do
 cp "$moddir/payload/$f" "$root/$f"
done
chmod 700 "$root/radio.sh" "$root/owly-xosd" "$root/wonder-init"
rm -f "$root/state/stop-supervisor"
# Binder shellCommand passes stdin/stdout/stderr to system services. A log
# labelled adb_data_file cannot be received there under SELinux Enforcing.
# Keep both supervisor output descriptors on a pipe; only the logger opens it.
rm -f "$root/state/supervisor.exit"
: > "$root/state/supervisor.log"
"$bb" setsid /system/bin/sh -c '
 /system/bin/sh "$1" 2>&1 | "$2" cat > "$3"
' k90-supervisor "$moddir/supervisor.sh" "$bb" "$root/state/supervisor.log" </dev/null >/dev/null 2>&1 8>&- &
for i in $(seq 1 150); do
 if grep -q '^SUPERVISOR_READY$' "$root/state/supervisor.log"; then
  echo "K90 AirDrop backend ready."
  exit 0
 fi
 if test -r "$root/state/supervisor.exit"; then break; fi
 sleep 0.2
done
tail -30 "$root/state/supervisor.log"
if test -r "$root/state/supervisor.exit"; then
 rc=$(cat "$root/state/supervisor.exit")
 case "$rc" in ''|*[!0-9]*|0) exit 1 ;; *) exit "$rc" ;; esac
fi
exit 1
