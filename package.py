# SPDX-License-Identifier: GPL-2.0-only
"""Build a flashable public module; external firmware is omitted by default."""
from pathlib import Path
import argparse
import hashlib
import shutil
import zipfile

ROOT = Path(__file__).resolve().parent
MODULE = ROOT / 'module'
FIRMWARE = 'payload/firmware/ezif.bin'
FW_SHA = '37d409044902fb5e4eb47aff5c543adb0dfd6a56e4e38ff723feb823bc8b522f'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--firmware', type=Path, help='Private local build only: embed this verified firmware')
    args = parser.parse_args()
    firmware = args.firmware.read_bytes() if args.firmware else None
    if firmware is not None and hashlib.sha256(firmware).hexdigest() != FW_SHA:
        raise SystemExit('Firmware SHA-256 mismatch')
    for line in (MODULE / 'payload/installation.sha256').read_text().splitlines():
        digest, name = line.split(None, 1)
        name = name.strip()
        if name == 'firmware/ezif.bin':
            if digest != FW_SHA:
                raise SystemExit('Unexpected firmware identity in manifest')
            continue
        path = MODULE / 'payload' / name
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise SystemExit('Payload hash mismatch: ' + name)
    apk = ROOT / 'app/build/Annibale-XOS-Compat-v0.4.5-Native.apk'
    if apk.is_file():
        shutil.copyfile(apk, MODULE / 'companion/Annibale-XOS-Compat.apk')
    files = {p.relative_to(MODULE).as_posix(): p.read_bytes() for p in sorted(MODULE.rglob('*'))
             if p.is_file() and p.relative_to(MODULE).as_posix() != FIRMWARE
             and p.name != 'files.sha256' and 'META-INF' not in p.parts}
    files['LICENSE'] = (ROOT / 'LICENSE').read_bytes()
    files['NOTICE.md'] = (ROOT / 'NOTICE.md').read_bytes()
    for path in sorted((ROOT / 'LICENSES').glob('*')):
        if path.is_file():
            files['LICENSES/' + path.name] = path.read_bytes()
    version = next(line.split('=', 1)[1] for line in (MODULE / 'module.prop').read_text(encoding='utf-8').splitlines() if line.startswith('version='))
    files['SOURCE.txt'] = f'Corresponding sources and per-component licensing:\nhttps://github.com/RyanChanUnknown/K90-AirDrop\nRelease: v{version}\nExternal Samsung firmware is not included in this public archive.\n'.encode()
    manifest = {name: hashlib.sha256(data).hexdigest() for name, data in files.items() if name != 'customize.sh'}
    manifest[FIRMWARE] = FW_SHA
    data = ''.join(f'{manifest[name]}  {name}\n' for name in sorted(manifest)).encode()
    (MODULE / 'files.sha256').write_bytes(data)
    files['files.sha256'] = data
    if firmware is not None:
        files[FIRMWARE] = firmware
    dest = ROOT / 'dist' / f'K90-AirDrop-KernelSU-v{version}{"-with-firmware" if firmware else ""}.zip'
    dest.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(files):
            entry = zipfile.ZipInfo(name, (2026, 11, 20, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = (0o100700 if name.endswith('.sh') else 0o100600) << 16
            archive.writestr(entry, files[name])
    print(dest.name)
    print('SHA-256:', hashlib.sha256(dest.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
