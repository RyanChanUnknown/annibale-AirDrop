"""Compare a rebuilt WLAN module with this K90's stock module and ABI."""
import argparse
from pathlib import Path
import re
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("module", type=Path)
parser.add_argument("--ndk-bin", type=Path, required=True)
args = parser.parse_args()
here = Path(__file__).resolve().parent
stock = here / "qca_cld3_kiwi_v2.ko"

def output(tool, *arguments):
    return subprocess.check_output([str(args.ndk_bin / tool), *map(str, arguments)], text=True)

def module_relocations(path):
    elf = output("llvm-readelf", "-Wr", path)
    section = elf.split("Relocation section '.rela.gnu.linkonce.this_module'", 1)[1].split("\n\n", 1)[0]
    return {
        name: int(offset, 16)
        for offset, name in re.findall(r"^([0-9a-f]+).*?\b(init_module|cleanup_module)\b", section, re.M)
    }

def kcfi(path):
    return {
        name.removeprefix("__kcfi_typeid_"): int(value, 16)
        for name, _, value, _ in (line.split() for line in output("llvm-nm", "--format=posix", path).splitlines()
                                  if line.startswith("__kcfi_typeid_"))
    }

module_relocs = module_relocations(args.module)
stock_relocs = module_relocations(stock)
if module_relocs != stock_relocs or not module_relocs:
    sys.exit(f"Unexpected struct module relocations: {module_relocs}; stock {stock_relocs}")

records = here.parent / "pandora" / "tools" / "kocrc.py"
def imports(path):
    return {name: crc for crc, name, kind, _ in (
        line.split() for line in subprocess.check_output(
            [sys.executable, str(records), str(path)], text=True,
        ).splitlines()
    ) if kind == "import"}

expected = {name: crc.removeprefix("0x") for crc, name, *_ in (
    line.split() for line in (here / "combined.symvers").read_text().splitlines()
)}
expected.update({name: crc for crc, name, kind, owner in (
    line.split() for line in (here / "builds/live/module-crcs.txt").read_text().splitlines()
) if kind == "export" and owner == "houji_wonder_bridge.ko"})
new = imports(args.module)
old = imports(stock)
wrong = {name: (new[name], expected.get(name)) for name in new if new[name] != expected.get(name)}
new_types, stock_types = kcfi(args.module), kcfi(stock)
common = sorted(new_types.keys() & stock_types.keys())
wrong_types = {name: (stock_types[name], new_types[name]) for name in common if new_types[name] != stock_types[name]}

print(f"Verified init/exit offsets {module_relocs}")
print(f"Imports: {len(new)}, stock overlap {len(new.keys() & old.keys())}, mismatched {len(wrong)}")
print(f"KCFI comparison: {len(common)} shared type IDs, mismatched {len(wrong_types)}")
print("Missing stock imports:", " ".join(sorted(old.keys() - new.keys())))
print("Added imports:", " ".join(sorted(new.keys() - old.keys())))
if wrong:
    print("CRC problems:", wrong)
if wrong_types:
    print("KCFI differences:", wrong_types)
if not new or not common or wrong or wrong_types:
    sys.exit("Module ABI audit failed")
