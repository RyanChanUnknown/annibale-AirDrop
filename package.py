from pathlib import Path
import shutil,hashlib,zipfile
r=Path(__file__).resolve().parent;m=r/'module'
fw=m/'payload/firmware/ezif.bin'
if not fw.is_file():
 raise SystemExit('Provide the external firmware first: python tools/prepare_firmware.py <ezif.bin>')
for line in (m/'payload/installation.sha256').read_text().splitlines():
 digest,name=line.split(None,1);p=m/'payload'/name.strip()
 if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:
  raise SystemExit('Payload hash mismatch: '+name)
apk=r/'app/build/Annibale-XOS-Compat-v0.4.5-Native.apk'
if apk.is_file():shutil.copyfile(apk,m/'companion/Annibale-XOS-Compat.apk')
(r/'dist').mkdir(exist_ok=True)
(m/'files.sha256').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(m).as_posix()+'\n' for p in sorted(m.rglob('*')) if p.is_file() and p.name not in ['files.sha256','customize.sh'] and 'META-INF' not in p.parts),newline='\n')
with zipfile.ZipFile(r/'dist/K90-AirDrop-KernelSU-v0.3.5-native.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(m.rglob('*')):
  if p.is_file():z.write(p,p.relative_to(m).as_posix())
print('NATIVE_ZIP_BUILT')
