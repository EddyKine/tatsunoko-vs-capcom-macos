"""Compile and package the public settings app without private portable data."""
from pathlib import Path
import argparse,hashlib,plistlib,shutil,subprocess,tempfile,zipfile
r=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=r/'build');a=p.parse_args()
out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
app=out/'TvC Settings.app'
if app.exists():raise SystemExit('El destino ya existe. Usa --output con otra carpeta para conservarlo.')
# Sign on the native filesystem so exFAT AppleDouble files cannot enter the signature.
with tempfile.TemporaryDirectory(prefix='tvc-public-build-') as temp:
    stage=Path(temp)/app.name;mac=stage/'Contents/MacOS';res=stage/'Contents/Resources'
    mac.mkdir(parents=True);(res/'Shaders').mkdir(parents=True)
    shutil.copyfile(r/'Info.plist',stage/'Contents/Info.plist')
    for shader in ('TvC_CRT_Adaptive_Soft.glsl','TvC_CRT_Adaptive_Strong.glsl'):
        shutil.copyfile(r/'Resources/Shaders'/shader,res/'Shaders'/shader)
    for name in ('LICENSE','NOTICE.md'):
        shutil.copyfile(r/name,res/name)
    subprocess.run(['xcrun','swiftc','-parse-as-library','-O','-target','arm64-apple-macos13.0','-framework','SwiftUI','-framework','AppKit',str(r/'Sources/TvCSettings.swift'),'-o',str(mac/'TvCSettings')],check=True)
    (mac/'TvCSettings').chmod(0o755)
    subprocess.run(['codesign','--force','--sign','-',str(stage)],check=True)
    subprocess.run(['codesign','--verify','--deep','--strict',str(stage)],check=True)
    deps=subprocess.check_output(['otool','-L',str(mac/'TvCSettings')],text=True)
    if '/opt/homebrew/' in deps:raise SystemExit('Unexpected Homebrew runtime dependency')
    archive=out/'TvC-Settings-v0.6.3-public-macOS-arm64.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for f in sorted(stage.rglob('*')):
            if f.is_file():z.write(f,f.relative_to(stage.parent))
        z.write(r/'LEEME-RELEASE.txt','LEEME.txt')
    shutil.copytree(stage,app,copy_function=shutil.copyfile)
    for f in (app/'Contents/MacOS').iterdir():f.chmod(0o755)
    subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
(out/'SHA256SUMS.txt').write_text(hashlib.sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print(archive)
