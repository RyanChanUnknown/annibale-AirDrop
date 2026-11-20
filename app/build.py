from pathlib import Path
import os, subprocess, zipfile, shutil

root=Path(__file__).resolve().parent
sdk=Path(os.environ['ANDROID_HOME'])
tools=sdk/'build-tools'/'36.0.0'
android=sdk/'platforms'/'android-36'/'android.jar'
build=root/'build'
for d in ['stubs','classes','generated','dex']:
    stage=(build/d).resolve()
    if not stage.is_relative_to(build.resolve()) or stage==build.resolve():
        raise RuntimeError('Unsafe build path')
    if stage.exists():
        shutil.rmtree(stage)
    stage.mkdir(parents=True)
def run(*args):
    subprocess.run([str(a) for a in args],check=True,cwd=root)
run(tools/'aapt2.exe','compile','--dir',root/'res','-o',build/'res.zip')
run(tools/'aapt2.exe','link','-I',android,'--manifest',root/'AndroidManifest.xml',
    '-A',root/'assets','--java',build/'generated','-o',build/'unsigned.apk',build/'res.zip')
run('javac','--release','8','-encoding','UTF-8','-d',build/'stubs',*root.glob('stubs/**/*.java'))
run('javac','--release','8','-encoding','UTF-8','-cp',str(android)+';'+str(build/'stubs'),
    '-d',build/'classes',*root.glob('src/**/*.java'),*build.glob('generated/**/*.java'))
run(tools/'d8.bat','--lib',android,'--classpath',build/'stubs','--min-api','33','--output',build/'dex',*build.glob('classes/**/*.class'))
with zipfile.ZipFile(build/'unsigned.apk','a') as apk:
    apk.write(build/'dex/classes.dex','classes.dex')
key=build/'module-test.jks'
if not key.exists():
    run('keytool','-genkeypair','-keystore',key,'-storepass','annibale-local-test',
        '-keypass','annibale-local-test','-alias','annibale','-dname','CN=Annibale XOS Compat QS Test',
        '-keyalg','RSA','-validity','3650')
run(tools/'apksigner.bat','sign','--ks',key,'--ks-pass','pass:annibale-local-test',
    '--out',build/'Annibale-XOS-Compat-v0.4.5-Native.apk',build/'unsigned.apk')
run(tools/'apksigner.bat','verify',build/'Annibale-XOS-Compat-v0.4.5-Native.apk')
print('Built',build/'Annibale-XOS-Compat-v0.4.5-Native.apk')
