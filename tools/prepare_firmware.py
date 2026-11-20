from pathlib import Path
import argparse, hashlib, shutil
parser = argparse.ArgumentParser(description="Verify and stage the locally supplied Samsung EZIF firmware")
parser.add_argument("firmware", type=Path)
args = parser.parse_args()
if not args.firmware.is_file():
    raise SystemExit("Firmware file not found")
expected = "37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f"
if hashlib.sha256(args.firmware.read_bytes()).hexdigest() != expected:
    raise SystemExit("Firmware SHA-256 mismatch; nothing copied")
dest = Path(__file__).resolve().parents[1] / "module/payload/firmware/ezif.bin"
dest.parent.mkdir(parents=True, exist_ok=True)
if args.firmware.resolve() != dest.resolve():
    shutil.copyfile(args.firmware, dest)
print("Firmware verified and staged in a Git-ignored path")
