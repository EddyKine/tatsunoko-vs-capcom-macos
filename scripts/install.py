"""Install only TvC Settings; preserve UserData and every previous app backup."""
from pathlib import Path
import argparse,datetime,shutil,subprocess
r=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('portable',type=Path);p.add_argument('--app',type=Path,default=r/'build/TvC Settings.app');a=p.parse_args()
dest=a.portable.resolve();src=a.app.resolve()
if not (dest/'UserData').is_dir() or not (dest/'Tatsunoko vs Capcom.app').is_dir():
    raise SystemExit('La carpeta debe contener UserData y Tatsunoko vs Capcom.app.')
if not (src/'Contents/MacOS/TvCSettings').is_file():raise SystemExit('Compila primero con bash build.sh.')
subprocess.run(['codesign','--verify','--deep','--strict',str(src)],check=True)
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
stage=dest/('.TvC Settings-install-'+stamp+'.app');target=dest/'TvC Settings.app'
shutil.copytree(src,stage,copy_function=shutil.copyfile,ignore=shutil.ignore_patterns('._*','.DS_Store'))
(stage/'Contents/MacOS/TvCSettings').chmod(0o755)
subprocess.run(['codesign','--verify','--deep','--strict',str(stage)],check=True)
backup=dest/('TvC Settings backup-'+stamp+'.app')
if target.is_symlink():raise SystemExit('El destino es un enlace simbólico; no se reemplazó.')
had_previous=target.exists()
if had_previous:target.rename(backup)
try:stage.rename(target)
except Exception:
    if had_previous and not target.exists():backup.rename(target)
    raise
print('Instalado:',target)
if had_previous:print('Respaldo conservado:',backup)
print('UserData permanece intacto. No se alteraron ajustes de seguridad de macOS.')
