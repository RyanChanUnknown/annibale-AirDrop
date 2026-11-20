#!/system/bin/sh
root=/data/adb/annibale-xos
rm -f "$root/background-receive.enabled"
if test -d "$root/state"; then
 touch "$root/state/stop-broker" "$root/state/stop-supervisor"
fi
cmd statusbar remove-tile org.annibale.xoscompat/.AirDropTile >/dev/null 2>&1 || true
