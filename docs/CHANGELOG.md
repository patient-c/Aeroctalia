# Changelog

## Sin publicar

- Los colores dejan de estar fijos: el prompt de oh-my-posh, `ls`/`lsd`, `grep` y `bat` toman la paleta que Noctalia genera del wallpaper. `~/.config/noctalia/animfetch.toml` la regenera al cambiar el fondo, y un `precmd` en `~/.config/zsh/aeroctalia-themes.zsh` recarga `LS_COLORS` y `GREP_COLORS` en las terminales ya abiertas. `animfetch` arranca en modo `--pin`, y `clear` o `Ctrl+L` lo desarman.
- El tema de iconos pasa de AwOken a **KrystalSVG**. Este no es un paquete: se publica como asset de la release de Aeroctalia y `install.sh` lo descarga verificando su sha256, con los stubs ya resueltos y `Inherits=Papirus,hicolor` asegurado. Sus credenciales y su sha256 van en `meta/krystalsvg.conf`; el asset es el tarball de upstream reempaquetado sin modificar, para que el hash sea reproducible.
- AwOken desaparece de todas las configuraciones. El tema se sincroniza además en `qt5ct` y `qt6ct`, no solo en `kdeglobals`: Qt lee el nombre del tema de ahí, y por eso el lanzador de Noctalia se quedaba atrás mientras Dolphin y GTK sí cambiaban.
- `rice_fix_icons` busca el tema también en `~/.local/share/icons/`, no solo en `/usr/share/icons/`. Un tema de usuario era invisible para el instalador.
- `animfetch-bin` entra en los paquetes AUR y `zstd` en los oficiales (para descomprimir el tema).
- `tools/verify-dolphin.sh` lee el nombre del tema de la configuración en vez de tener AwOken hardcodeado.
- Se retira Timeshift de la lista de paquetes.
- Se retiran Gruvbox, DBeaver, Postman, LibreOffice, Remmina, Spotify y la dependencia obligatoria de Flatpak/Flathub.
- El sonido de inicio del tema SDDM espera a que exista un dispositivo de audio real, y `install.sh` arranca el audio del greeter junto con su sesión. El usuario `sddm` se añade al grupo `audio`, y `--verify` lo comprueba.
- Se añaden Qt Multimedia y su backend para reproducir ese sonido.
- `--verify` reconoce correctamente el wallpaper por defecto de Noctalia.
- El perfil `author` sustituye `$HOME` por el home de destino y configura wallpapers con paleta M3 Content.
- Se evita el conflicto `pipewire-jack`/`jack2` conservando `jack2` si ya está instalado.

## 1.11.1

- Confirmaciones explícitas antes de los cambios importantes.
- Nuevo modo `--restore` para volver al último respaldo.
- Los cambios temporales de `pacman.conf` se revierten si ocurre un error o una interrupción.
- Chaotic-AUR se trata como repositorio externo y requiere confirmación.
- Se eliminan referencias a un usuario concreto en la configuración principal.
- Mejor resumen final, manejo de errores y visibilidad de advertencias.

## 1.11.0

- Dolphin y los iconos AwOken se configuran en un paso dedicado que regenera el wrapper, el `.desktop`, el drop-in de systemd y `environment.d`.
- Dolphin aplica el tema Kvantum e iconos AwOken también al abrirse desde el navegador.
- Nuevo `tools/verify-dolphin.sh` para comprobar las tres formas de abrir Dolphin.
- Nuevos modos `--verify`, `--uninstall` y `--copy-all`, y un log en `~/.local/state/rice-install/<fecha>/install.log`.
- Se corrige un error que rompía `--dry-run` en instalaciones limpias de Arch.
- `paru` se trata igual que `yay`.
- Se deja de copiar estado propio de otro equipo (GIMP, dconf, historial de Noctalia, etc.).
- `dunst` sale de la lista base (Noctalia ya gestiona las notificaciones) y `dolphin` pasa a ser paquete base.

## 1.10.1

Versión base inicial.

## English

## Unreleased

- Timeshift is removed from the package lists.
- Removed Gruvbox, DBeaver, Postman, LibreOffice, Remmina, Spotify and the mandatory Flatpak/Flathub dependency.
- The SDDM theme's startup sound waits for a real audio device, and `install.sh` starts the greeter's audio together with its session. The `sddm` user is added to the `audio` group, and `--verify` checks it.
- Added Qt Multimedia and its backend to play that sound.
- `--verify` now recognizes Noctalia's default wallpaper correctly.
- The `author` profile expands `$HOME` for the install target and configures wallpapers with the M3 Content palette.
- The installer also sets AwOken in GTK GSettings and verifies the value.
- Avoids the `pipewire-jack`/`jack2` conflict by keeping `jack2` when it is already installed.

## 1.11.1

- Explicit confirmations before important changes.
- New `--restore` mode to return to the latest backup.
- Temporary `pacman.conf` changes are reverted after errors or interruptions.
- Chaotic-AUR is treated as an external repository and requires confirmation.
- Removed references to a specific user from the main configuration.
- Improved final summary, error handling and warning visibility.

## 1.11.0

- Dolphin and AwOken icons are set up in a dedicated step that regenerates the wrapper, `.desktop`, systemd drop-in and `environment.d`.
- Dolphin applies the Kvantum theme and AwOken icons when launched from a browser as well.
- New `tools/verify-dolphin.sh` to check the three ways Dolphin can be launched.
- New `--verify`, `--uninstall` and `--copy-all` modes, and a log at `~/.local/state/rice-install/<date>/install.log`.
- Fixed a bug that broke `--dry-run` on clean Arch installations.
- `paru` is treated the same as `yay`.
- Machine-specific state from another system (GIMP, dconf, Noctalia history, etc.) is no longer copied.
- `dunst` is removed from the base list (Noctalia already handles notifications) and `dolphin` becomes a base package.

## 1.10.1

Initial baseline.