# Tatsunoko vs. Capcom para macOS — TvC Settings 0.6.3

Fuentes del configurador **TvC Settings 0.6.3**, recuperadas del respaldo estable del proyecto de Tatsunoko vs. Capcom: Ultimate All-Stars para Apple Silicon.

[Descargar TvC Settings 0.6.3 público](https://github.com/EddyKine/tatsunoko-vs-capcom-macos/releases/tag/settings-v0.6.3-public)

**Esta publicación contiene el configurador, no el juego completo.** Se necesita un portable compatible aportado por el usuario. No incluye el runtime ModernGekko, el módulo recompilado, datos extraídos del disco, claves, NAND, partidas ni imágenes del juego. Las fuentes originales del runtime y launcher del portable no se encontraron en este respaldo; no se atribuye a esta publicación una reconstrucción completa del juego.

## Funciones

- Resolución interna, pantalla completa y CRT con scanlines alineadas a píxeles.
- Controles Xbox, reasignación de Classic Controller y Wiimote horizontal.
- Pictogramas dinámicos de botones y acciones.
- Respaldos e importación de partidas STKE08, con staging y recuperación.
- Abrir y solicitar el cierre de la copia del juego situada junto al configurador.

El archivo estable documenta validación manual de 0.6.3 con el portable real. La edición pública conserva el código Swift y los shaders, pero omite las imágenes opcionales del mando. Sus scripts de instalación conservan los respaldos anteriores y no eliminan la cuarentena de macOS. Ver [procedencia y verificación](docs/PUBLICACION.md).

## Usar la descarga

Descomprime el ZIP y coloca la app en tu propia carpeta compatible:

```text
Tatsunoko vs Capcom Portable/
├── Tatsunoko vs Capcom.app   # aportada por el usuario
├── TvC Settings.app         # esta descarga
└── UserData/                # datos de tu copia
```

Cierra el configurador anterior y conserva su app con otro nombre antes de instalar. El configurador puede modificar ajustes y partidas al usar sus funciones: verifica primero en una copia de tu portable. No se instala automáticamente sobre las copias del desarrollador.

Requisito declarado: macOS 13+ y Apple Silicon. Build público comprobado en macOS 27.2; no probado en otro Mac físico. Firma ad hoc, sin notarización: Gatekeeper puede bloquear la apertura.

## Compilar

Se requieren Xcode Command Line Tools, Python 3 y Git. No necesita Homebrew ni librerías de terceros para ejecutar el configurador.

```sh
git clone https://github.com/EddyKine/tatsunoko-vs-capcom-macos.git
cd tatsunoko-vs-capcom-macos
bash build.sh
```

El resultado está en `build/TvC Settings.app`, junto al ZIP y SHA256SUMS.txt. Para conservar un build anterior: `bash build.sh --output build/otro-build`.

Instalación opcional desde las fuentes, indicando tu propia copia de prueba:

```sh
bash install-to-portable.sh "/ruta/Tatsunoko vs Capcom Portable"
```

El instalador verifica la firma, prepara la app antes del reemplazo y guarda la anterior con fecha y hora. No instala archivos del juego ni escribe en UserData. No inicia el juego.

## Créditos

Luis Alberto Arias Soliz (EddyKine), con asistencia de ChatGPT de OpenAI. Código propio bajo [GPLv3](LICENSE); [avisos y componentes externos](NOTICE.md). ModernGekko, Dolphin y DolRecomp conservan sus autores y licencias. El código público no otorga derechos sobre el juego ni sus recursos.
