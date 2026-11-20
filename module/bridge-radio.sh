#!/system/bin/sh
# A client release returns to stock Wi-Fi with the discovery provider idle.
# Supervisor shutdown calls radio.sh restore directly to unload everything.
set -eu
case "${1:-status}" in
 restore) exec /system/bin/sh /data/adb/annibale-xos/radio.sh leave ;;
 *) exec /system/bin/sh /data/adb/annibale-xos/radio.sh "$@" ;;
esac
