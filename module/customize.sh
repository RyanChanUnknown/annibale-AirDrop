SKIPMOUNT=true
. "$MODPATH/verify.sh"
ui_print "- Checking hardware, OS, ABI, WLAN, framework and payload..."
verify_package "$MODPATH" || abort "! Compatibility failed; no APK changes were made."
set_perm_recursive "$MODPATH" 0 0 0700 0600
for script in action.sh backend-action.sh post-fs-data.sh service.sh bootstrap.sh uninstall.sh; do set_perm "$MODPATH/$script" 0 0 0700; done
apk_stage=$(mktemp /data/local/tmp/annibale-apk.XXXXXX) || abort "! Cannot stage APK."
cp "$MODPATH/companion/Annibale-XOS-Compat.apk" "$apk_stage" || { rm -f "$apk_stage"; abort "! APK staging failed."; }
chmod 644 "$apk_stage"
chcon u:object_r:shell_data_file:s0 "$apk_stage" || { rm -f "$apk_stage"; abort "! Cannot label APK."; }
ui_print "- Installing integrated LSPosed app..."
apk_result=$(pm install -r --user 0 "$apk_stage" 2>&1)
apk_rc=$?
rm -f "$apk_stage"
if test "$apk_rc" != 0 || ! printf '%s\n' "$apk_result" | grep -q '^Success$'; then
 ui_print "$apk_result"
 abort "! APK install failed; incompatible old signatures are not force-removed."
fi
ui_print "- Reboot, then activate K90 AirDrop in LSPosed (MIShare scope only)."
ui_print "- No separate app root authorization is required."
