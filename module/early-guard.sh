#!/system/bin/sh
early_guard() {
 for field in 'ro.product.device=annibale' 'ro.product.model=2510DRK44C' 'ro.soc.model=SM8750' 'ro.board.platform=sun' 'ro.build.version.sdk=37' 'ro.build.version.incremental=OS4.0.5.0.XPKCNXM'; do
  key=$(printf '%s' "$field" | cut -d= -f1)
  expected=$(printf '%s' "$field" | cut -d= -f2-)
  actual=$(getprop "$key")
  test "$actual" = "$expected" || { echo "EARLY_BOOT_REJECTED: $key expected=$expected actual=$actual"; return 1; }
 done
 echo '7cafb5c701086cc57855f3ba5502ac2fd2b1df22a6d167c331c8cd27216ad9c4  /proc/version' | sha256sum -c - || { echo EARLY_BOOT_REJECTED_KERNEL; return 1; }
 echo EARLY_BOOT_PASS
}
