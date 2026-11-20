"""Create a reference file for offline modpost from the two phone captures.

An import observed in a stock module contributes a CRC, but cannot establish
GPL status or namespace. The result is for compilation diagnostics only.
"""
from collections import defaultdict
from pathlib import Path
import sys

root = Path(__file__).resolve().parent
providers = {}
observed = defaultdict(set)
for filename in ("stock-wlan-crc.txt", "vendor-crc.txt"):
    for line in (root / filename).read_text().splitlines():
        crc, symbol, kind, module = line.split()
        if kind == "import":
            observed[symbol].add(crc)
        elif kind == "export" and module != "qca_cld3_kiwi_v2.ko":
            providers[symbol] = (crc, module.removesuffix(".ko"))

conflicts = []
for name, crcs in sorted(observed.items()):
    if len(crcs) != 1 or (name in providers and providers[name][0] not in crcs):
        conflicts.append((name, sorted(crcs), providers.get(name)))
    elif name not in providers:
        providers[name] = (next(iter(crcs)), "vmlinux")

for name, crcs, provider in conflicts:
    providers.pop(name, None)
    print(f"ambiguous {name}: imports={crcs}, vendor export={provider}", file=sys.stderr)
for name, (crc, owner) in sorted(providers.items()):
    print(f"0x{crc}\t{name}\t{owner}\tEXPORT_SYMBOL\t")
