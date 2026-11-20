#!/system/bin/sh
set -eu
moddir=${0%/*}
root=/data/adb/annibale-xos
state=$root/state
radio=$root/radio.sh
ksud=/data/adb/ksu/bin/ksud
rule='platform_app_36 default_android_service service_manager { find }'
bridge=
applied=0
stage=initializing
cleanup() {
 exit_rc=$?
 trap - EXIT TERM INT HUP
 set +e
 echo "SUPERVISOR_EXIT stage=$stage rc=$exit_rc"
 if test -n "$bridge"; then kill "$bridge" 2>/dev/null; wait "$bridge" 2>/dev/null; fi
 policy_rc=0
 if test "$applied" = 1; then
  "$ksud" sepolicy patch "deny $rule"
  policy_rc=$?
  echo "POLICY_REVERT rc=$policy_rc"
 fi
 restore_rc=1
 for i in $(seq 1 30); do
  sh "$radio" restore
  restore_rc=$?
  if test "$restore_rc" = 0; then break; fi
  echo "RESTORE_RETRY attempt=$i rc=$restore_rc"
  sleep 1
 done
 if test "$restore_rc" != 0; then echo RESTORE_FAILED >&2; fi
 if test "$exit_rc" = 0 && { test "$restore_rc" != 0 || test "$policy_rc" != 0; }; then exit_rc=1; fi
 printf 'stage=%s rc=%s restore_rc=%s policy_rc=%s\n' "$stage" "$exit_rc" "$restore_rc" "$policy_rc" > "$state/supervisor.result"
 echo "$exit_rc" > "$state/supervisor.exit"
 rm -f "$state/supervisor.pid"
 echo "SUPERVISOR_DONE rc=$exit_rc restore_rc=$restore_rc policy_rc=$policy_rc"
 exit "$exit_rc"
}
trap cleanup EXIT
trap 'stage=signal; exit 0' TERM INT HUP
step() { stage=$1; shift; echo "STEP_BEGIN $stage"; "$@"; echo "STEP_OK $stage"; }
echo $$ > "$state/supervisor.pid"
stage=uid_lookup
echo "STEP_BEGIN $stage"
packages=$(cmd package list packages -U com.miui.mishare.connectivity)
uid=$(printf '%s\n' "$packages" | awk '$1 == "package:com.miui.mishare.connectivity" && $2 ~ /^uid:[0-9]+$/ { sub(/^uid:/, "", $2); print $2 }')
case "$uid" in ''|*[!0-9]*) echo "UID_LOOKUP_FAILED output=$packages" >&2; exit 1 ;; esac
echo "STEP_OK uid_lookup uid=$uid"
step compatibility_apk pm path org.annibale.xoscompat
stage=selinux_enforcing
test "$(getenforce)" = Enforcing
echo "STEP_OK $stage"
step sepolicy_check_allow "$ksud" sepolicy check "allow $rule"
step sepolicy_check_deny "$ksud" sepolicy check "deny $rule"
step radio_idle sh "$radio" idle
stage=bridge_registration
echo "STEP_BEGIN $stage"
CLASSPATH="$root/xos-bridge.zip" XOS_RADIO_SCRIPT="$moddir/bridge-radio.sh" app_process /system/bin XosBridge "$uid" &
bridge=$!
for i in $(seq 1 20); do
 if service check com.domestic.xoscomm.IDomesticXOsComm/default | grep -q ': found$'; then break; fi
 kill -0 "$bridge"
 sleep 0.2
done
service check com.domestic.xoscomm.IDomesticXOsComm/default | grep -q ': found$'
echo "STEP_OK $stage pid=$bridge"
applied=1
step sepolicy_apply "$ksud" sepolicy patch "allow $rule"
stage=running
echo SUPERVISOR_READY
while test ! -e "$state/stop-supervisor" && test ! -e "$moddir/disable" && test ! -e "$moddir/remove"; do
 if ! kill -0 "$bridge" 2>/dev/null; then stage=bridge_exited; exit 1; fi
 sleep 1
done
stage=stop_requested
