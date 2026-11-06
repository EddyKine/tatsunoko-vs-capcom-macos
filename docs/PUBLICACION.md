# Publicación de TvC Settings 0.6.3 — 6 de noviembre de 2026

## Fuente recuperada

El respaldo estable contenía un ZIP anidado con fuentes 0.6.3. Su SHA256 se verificó antes de extraer:

```text
c7d1b5cda7d6570b14a7e1575a1b90048ecbb0b2a053f73fad59e4e21808912b  TvC-Settings-v0.6.3-source.zip
```

El archivo Swift y los dos shaders son idénticos a ese respaldo. La edición pública cambia el identificador del bundle a `com.eddykine.tvcsettings.public` y el número de build a 9. Los PNG opcionales de referencia del mando no se publican; la interfaz conserva el icono del sistema y las tarjetas dinámicas. Se documenta la licencia GPLv3 del material propio según la declaración de distribución que acompañaba al portable.

Se sustituyen los scripts de build e instalación para firmar en una carpeta temporal nativa, crear un ZIP mediante lista explícita y conservar un respaldo fechado antes de reemplazar el configurador. El instalador no elimina la cuarentena ni modifica UserData. No se ejecutó sobre el portable real.

## Verificaciones

- Build optimizado arm64 con SwiftUI/AppKit, objetivo mínimo macOS 13.0, aprobado en macOS 27.2.
- Código Swift y shaders comparados byte a byte con el respaldo.
- Firma ad hoc profunda/estricta válida en build, ZIP extraído y copia instalada de prueba.
- Sin dependencias de carga Homebrew.
- ZIP sin Game, Runtime, Module, UserData, discos, módulos recompilados, partidas, imágenes privadas ni AppleDouble.
- Dos instalaciones en un portable ficticio: respaldo anterior conservado, contenido de UserData intacto y firma válida.
- Interfaz observada en General, Control Xbox y Partidas; ausencia de juego y datos gestionada sin iniciar el runtime. No se importaron partidas ni se cambiaron mandos reales.

Las comprobaciones no certifican el juego completo ni una nueva sesión de combate. El respaldo anterior documentaba validación manual de la base 0.6.3 en el portable real. No se probó otro Mac físico ni se notarizó la app.

## Descarga

```text
2652f466ed28df1f36a8ac88ed264ea78aa88c3c4d6075397cf90e6fb13f5837  TvC-Settings-v0.6.3-public-macOS-arm64.zip
```

La release `settings-v0.6.3-public` distribuye únicamente el configurador y sus avisos. Para una publicación reconstruible del juego completo todavía deben localizarse las fuentes y revisiones exactas del runtime ModernGekko, del launcher y de la generación del módulo. Los binarios de esos componentes del portable privado no se incluyen en este repositorio ni en sus assets.
