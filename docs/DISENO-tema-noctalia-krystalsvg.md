# Diseño: tema que sigue a Noctalia + KrystalSVG por defecto

> Documento de trabajo. Es la fuente de verdad si se pierde el contexto: todo lo
> que sigue está decidido, con su "por qué". Los pasos se hacen en orden, uno
> por commit.

## Objetivo

Que el instalador de Aeroctalia deje el sistema con:

1. **Colores que siguen al wallpaper.** La paleta Material You que Noctalia
   genera del fondo se aplica al prompt, a `ls`/`lsd`, a `grep` y a `bat`.
2. **KrystalSVG como tema de iconos**, coherente en Qt (lanzador de Noctalia),
   GTK y Dolphin. AwOken desaparece.

## Decisiones ya tomadas

| Decisión | Elección | Por qué |
|---|---|---|
| Origen de KrystalSVG | Release propia en `github.com/patient-c/Aeroctalia` | Control total, sha256 verificable, cacheado entre re-ejecuciones, sin depender de blackysgate.de |
| AwOken | Fuera por completo | Dejarlo producía configs incoherentes (ver "El bug que motivó sacar AwOken") |
| animfetch `--pin` | Siempre por defecto | Aeroctalia es declarativo: no pregunta por lo obvio |
| Parches de KrystalSVG | Los dos, automáticos | Eran un trabajo manual que se perdía en cada instalación limpia |

### El bug que motivó sacar AwOken

Noctalia es Qt. Qt lee el nombre del tema de `~/.config/qt6ct/qt6ct.conf`,
**no** de `kdeglobals` (esto ya está escrito en `install.sh:1609`). Con AwOken
en el repo y KrystalSVG puesto a mano, el resultado era:

| fichero | tema |
|---|---|
| `~/.config/kdeglobals [Icons] Theme` | KrystalSVG |
| `~/.config/gtk-4.0/settings.ini` | KrystalSVG |
| `~/.config/qt6ct/qt6ct.conf` | **AwOken** ← el launcher se quedaba atrás |
| `~/.config/qt5ct/qt5ct.conf` | **AwOken** |

Aparte, `rice_fix_icons()` (`install.sh:1563`) solo mira
`/usr/share/icons/$ic_theme`. KrystalSVG vive en `~/.local/share/icons/`, así
que el instalador **ni lo ve**. Eso también se arregla.

## Ficheros nuevos en `home/`

`home/` es el esqueleto del `$HOME` destino: `install.sh:1011-1055` lo copia tal
cual, sustituyendo `/home/placeholder` por el `$HOME` real (`meta/origin.txt`).

| Fichero | Origen |
|---|---|
| `home/.local/bin/noctalia-animfetch-palette` | copia literal de `~/.local/bin/noctalia-animfetch-palette` |
| `home/.local/bin/noctalia-shell-theme` | copia literal de `~/.local/bin/noctalia-shell-theme` |
| `home/.config/animfetch/config.toml` | copia literal, paleta Frutiger Aero de reserva |
| `home/.config/oh-my-posh/paradox.template.json` | copia literal |
| `home/.config/noctalia/animfetch.toml` | reescrito con `/home/placeholder` en vez de `/home/patient` |
| `home/.config/zsh/aeroctalia-themes.zsh` | bloque de shell, sourceado desde `home/.zshrc` |

**Generados, NO se versionan** (van a `.gitignore` y `packages/skip-home.txt`):

- `home/.config/animfetch/palette.json`
- `home/.config/animfetch/lscolors`
- `home/.config/animfetch/grep_colors`
- `home/.config/oh-my-posh/paradox-noctalia.omp.json`
- `home/.config/bat/themes/noctalia.tmTheme` (lo escribe el generador)

## Ficheros a modificar

| Fichero | Cambio |
|---|---|
| `home/.zshrc` | un `source` al bloque de temas |
| `packages/aur.txt` | fuera `awoken-icons`; dentro `animfetch-bin` |
| `packages/base.txt` | dentro `zstd` (para descomprimir el tarball) |
| `packages/skip-home.txt` | excluir los generados de arriba |
| `.gitignore` | idem |
| `install.sh` | `chmod +x` a los scripts, generar al final, y el bloque de iconos |
| `README.md`, `LICENSES.md`, `docs/CHANGELOG.md` | AwOken → KrystalSVG |

## El pipeline de KrystalSVG

1. El instalador lee la URL y el sha256 de `meta/krystalsvg.sha256`.
2. Descarga `krystalsvg-bc-extras.tar.zst` de la release `v$RICE_VERSION`.
3. Verifica el sha256. Si no coincide, para: no se instala un tema sin verificar.
4. Lo extrae en `~/.local/share/icons/KrystalSVG-Plasma5up-scalable-icontheme-blackysgate.de`.
5. Aplica los dos parches, **idempotentes**:
   - `index.theme`: `Inherits=Papirus,hicolor`. El upstream trae
     `synbolic-bullschit,hicolor`, que no existe en Arch y dejaba ~40 iconos de
     apps modernas vacíos.
   - Stubs: los directorios de tamaños raster (8x8…512x512) apuntan a
     `scalable`, y los `scalable/categories/*` que faltan se enlazan a su
     equivalente en `scalable/preferences/`.
6. `gtk-update-icon-cache`.
7. Verifica con `tools/qt-icon-probe.sh` (ya existe y mide de verdad qué tema
   resolvió Qt).

## El bloque de shell

Un único fichero `~/.config/zsh/aeroctalia-themes.zsh`, sourceado desde el
`.zshrc`. Contiene:

- `af_pin` / `af_unpin` y `clear` / `Ctrl+L` (que desarman el pin)
- `_noctalia_sync` en `precmd`: relée `lscolors` y `grep_colors` cuando cambian
- `omp_reload`: re-inicializa oh-my-posh (lo cachea en memoria, no se auto-actualiza)
- `BAT_THEME=noctalia`, `alias grep='grep --color=auto'`

## Qué se actualiza solo y qué no

| | al cambiar el fondo | terminales ya abiertas |
|---|---|---|
| animfetch | sí | sí |
| ls / lsd | sí | sí |
| grep | sí | sí |
| bat | sí | sí |
| prompt de oh-my-posh | sí en terminales nuevas | `omp_reload` |

## Límites conocidos

- **`man` no se incluye.** En la máquina de desarrollo no está instalado, así
  que la parte de man no se ha podido probar. Queda documentada como opcional.
- **`colors_changed` no salta con `theme-mode-toggle`.** Comprobado con un hook
  sonda. El wallpaper sí dispara los hooks; cambiar el modo claro/oscuro, no.
  No prometer eso en la documentación.
- **KrystalSVG son 477 MB** descomprimido. El tarball `.tar.zst` es mucho menor,
  pero sigue siendo la descarga más grande del instalador.

## Verificación

- `bash -n install.sh` y `shellcheck` si está disponible
- `./install.sh --dry-run` y `./install.sh --verify`
- En una máquina limpia real: wallpaper → palette → los 4 salidas coherentes

## Riesgo conocido

El `.zshrc` del usuario y `home/.zshrc` difieren en 175 líneas, casi todas
personales. **No se copia el `.zshrc` del usuario**: se extrae solo nuestro
delta. Si alguien.mergea esto sobre un fork, que revise ese fichero.