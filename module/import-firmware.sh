#!/system/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
firmware_sha=37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f
firmware_ok() {
 test -f "$1" && test "$(sha256sum "$1" | awk '{print $1}')" = "$firmware_sha"
}
import_firmware() {
 destination="$1/payload/firmware/ezif.bin"
 if test -e "$destination"; then
  firmware_ok "$destination" || { echo 'FIRMWARE_REJECTED: bundled firmware hash mismatch'; return 1; }
  echo FIRMWARE_BUNDLED_VERIFIED
  return 0
 fi
 for source in /data/adb/modules/annibale_airdrop/payload/firmware/ezif.bin \
  /data/adb/annibale-xos/firmware/ezif.bin \
  /sdcard/Download/s24u-amss20.bin /sdcard/Download/ezif.bin; do
  if firmware_ok "$source"; then
   mkdir -p "${destination%/*}" || return 1
   cp "$source" "$destination.pending" && firmware_ok "$destination.pending" &&
    chmod 600 "$destination.pending" && mv "$destination.pending" "$destination" || {
     rm -f "$destination.pending"
     echo 'FIRMWARE_REJECTED: copying or verification failed'
     return 1
    }
   echo "FIRMWARE_IMPORTED: $source"
   return 0
  fi
 done
 echo 'FIRMWARE_REJECTED: no matching S24 Ultra EZIF firmware found'
 echo 'Place verified s24u-amss20.bin in /sdcard/Download/ and retry.'
 echo "Required SHA-256: $firmware_sha"
 return 1
}
