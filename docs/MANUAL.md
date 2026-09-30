# Solución de problemas

`install.sh` no puede hacer algunos pasos por ti. Esta guía cubre esos pasos y los problemas más comunes.

Para problemas con **Dolphin, iconos o Kvantum**, consulta [DOLPHIN.md](DOLPHIN.md).

## Después de instalar

Ejecuta estos comandos solo si cambiaste `/etc/mkinitcpio.conf` o `/etc/default/grub` (con otro bootloader, el comando es distinto):

```
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Después, **cierra sesión y vuelve a entrar**. Hyprland lee su configuración al arrancar.

Para comprobar la instalación:

```
./install.sh --verify
```

## Ajustes que dependen de tu equipo

### Monitores

`monitors.conf` contiene la configuración de pantallas del equipo de ejemplo. Regenérala para el tuyo:

```
nwg-displays
```

### Particiones y cifrado

`fstab` y `crypttab` de `machine/etc/` contienen UUID de otro equipo. `install.sh` solo los copia si no existen, y una instalación nueva de Arch ya los tiene.

## Problemas comunes

### Hyprland no arranca

```
hyprctl version
journalctl --user -b | grep -i hypr
```

La causa más habitual es que falte `~/.config/hypr/monitors.conf`. Se regenera con `nwg-displays`.

### Los temas Qt no se ven

```
echo $QT_QPA_PLATFORMTHEME     # debe mostrar qt6ct
kvantummanager --preview KvRoughGlass
```

Si cambias esa variable, cierra sesión y vuelve a entrar. Si el problema es solo Dolphin, consulta [DOLPHIN.md](DOLPHIN.md).

### El tema del login no aparece

```
ls /usr/share/sddm/themes/
cat /etc/sddm.conf          # debe decir Current=win7-sddm-theme
```

El tema está en `assets/sddm/` y `install.sh` lo copia. Si falta, ejecuta `./install.sh --no-packages`.

### La máquina no llega al login

El gestor de acceso es **SDDM**. Desde una TTY (`Ctrl+Alt+F3`):

```
sudo systemctl enable --now sddm
```

### El sonido de inicio del login no suena

`install.sh` ya configura lo necesario (grupo `audio` para `sddm`, paquetes de audio y arranque temprano de PipeWire). Si aun así no suena, comprueba lo siguiente y **reinicia**:

```
id -nG sddm | tr ' ' '\n' | grep -x audio     # debe aparecer "audio"
wpctl get-volume @DEFAULT_AUDIO_SINK@         # "[MUTED]" significa silenciado
sudo ./install.sh --verify
```

Si `sddm` no está en el grupo `audio`:

```
sudo usermod -aG audio sddm
```

### El cursor del login es Adwaita

`install.sh` corrige `/usr/share/icons/default/index.theme` e instala un hook de pacman (`rice-cursor.hook`) que lo mantiene tras las actualizaciones.

```
grep Inherits /usr/share/icons/default/index.theme
ls /etc/pacman.d/hooks/rice-cursor.hook
```

### Bluetooth o red

```
sudo systemctl enable --now bluetooth
```

La red usa `iwd` como backend.

### El prompt se ve raro o la terminal abre en bash

La configuración del prompt vive en `~/.zshrc`, así que solo se aplica con zsh.

```
getent passwd $USER | cut -d: -f7    # debe terminar en /zsh
chsh -s /bin/zsh $USER
```

### Un paquete no se encuentra

`install.sh` valida cada lista de paquetes e indica cuál falta. Causas típicas:

1. **Chaotic-AUR no está habilitado.** `./install.sh` puede agregarlo con tu confirmación; con `--no-chaotic` se compilan desde AUR.
2. **La base de pacman está desactualizada.** Ejecuta `sudo pacman -Sy` y reintenta.
3. **El paquete fue renombrado.** Abre un issue con el nombre para actualizar `packages/`.

### Conflictos entre paquetes ("X and Y are in conflict")

El instalador pregunta cómo resolverlos. Los más comunes:

| Paquete          | Choca con                | Motivo                                   |
| ---------------- | ------------------------ | ---------------------------------------- |
| `pipewire-pulse` | `pulseaudio`             | Cumplen el mismo rol.                    |
| `wireplumber`    | `pipewire-media-session` | Reemplazo directo.                       |
| `7zip`           | `p7zip`                  | `7zip` ya incluye `p7zip`.               |
| `qt6ct-kde`      | `qt6ct`                  | La versión parcheada reemplaza a la otra. |

No se instala `pipewire-jack`, para conservar `jack2`. Si necesitas la compatibilidad JACK de PipeWire, revisa primero qué depende de `jack2`. No ejecutes `pacman -R` a ciegas sobre paquetes en conflicto.

### Un paquete de AUR no compila

Si aparece `sudo: a terminal is required to read the password`, renueva sudo y reintenta:

```
sudo -v
```

Los logs de compilación están en `/tmp/rice-aur/<paquete>.log`.

### El script se detuvo de golpe

El instalador muestra la línea, el código de salida y el comando que falló. Al reportar el problema, incluye esos tres datos y el log (`/tmp/rice-install.log`).

Para continuar sin instalar paquetes:

```
./install.sh --no-packages
```

### Paquetes de GPU que ya no existen

`install.sh` omite los paquetes de `gpu-*.txt` que no estén disponibles. Si ves un nombre antiguo (por ejemplo `libva-mesa-driver`), revisa la lista de tu GPU en `packages/`.

### `noctalia.lua` se regenera con errores

Noctalia puede regenerar `noctalia.lua` con una línea que rompe la función `error()` de Lua. El repositorio ya lo corrige y `hyprland.lua` lo carga con `pcall`, por lo que no debería afectar el arranque.

## Rolling release

1. Lee los anuncios de Arch antes de ejecutar `pacman -Syu`; Hyprland cambia con frecuencia.
2. Haz una copia de seguridad o un snapshot antes de actualizar, con la herramienta que prefieras.
3. Guarda tu configuración personal en un repositorio aparte del clon público.

## English

# Troubleshooting

`install.sh` cannot do some steps for you. This guide covers those steps and the most common problems.

For **Dolphin, icons or Kvantum** issues, see [DOLPHIN.md](DOLPHIN.md).

## After installation

Run these commands only if you changed `/etc/mkinitcpio.conf` or `/etc/default/grub` (other bootloaders use different commands):

```
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Then **log out and back in**. Hyprland reads its configuration at startup.

To check the installation:

```
./install.sh --verify
```

## Machine-specific settings

### Monitors

`monitors.conf` contains the display configuration of the sample machine. Regenerate it for yours:

```
nwg-displays
```

### Partitions and encryption

The `fstab` and `crypttab` files in `machine/etc/` contain UUIDs from another machine. `install.sh` only copies them if they do not exist, and a fresh Arch installation already has them.

## Common problems

### Hyprland does not start

```
hyprctl version
journalctl --user -b | grep -i hypr
```

The most common cause is a missing `~/.config/hypr/monitors.conf`. Regenerate it with `nwg-displays`.

### Qt themes are missing

```
echo $QT_QPA_PLATFORMTHEME     # should print qt6ct
kvantummanager --preview KvRoughGlass
```

If you change that variable, log out and back in. If only Dolphin is affected, see [DOLPHIN.md](DOLPHIN.md).

### The login theme does not appear

```
ls /usr/share/sddm/themes/
cat /etc/sddm.conf          # should say Current=win7-sddm-theme
```

The theme is in `assets/sddm/` and `install.sh` copies it. If it is missing, run `./install.sh --no-packages`.

### The machine does not reach the login screen

The login manager is **SDDM**. From a TTY (`Ctrl+Alt+F3`):

```
sudo systemctl enable --now sddm
```

### The login startup sound does not play

`install.sh` already sets up what is needed (`audio` group for `sddm`, audio packages and early PipeWire startup). If it still does not play, check the following and **reboot**:

```
id -nG sddm | tr ' ' '\n' | grep -x audio     # should print "audio"
wpctl get-volume @DEFAULT_AUDIO_SINK@         # "[MUTED]" means muted
sudo ./install.sh --verify
```

If `sddm` is not in the `audio` group:

```
sudo usermod -aG audio sddm
```

### The login cursor is Adwaita

`install.sh` fixes `/usr/share/icons/default/index.theme` and installs a pacman hook (`rice-cursor.hook`) that keeps the fix after upgrades.

```
grep Inherits /usr/share/icons/default/index.theme
ls /etc/pacman.d/hooks/rice-cursor.hook
```

### Bluetooth or network

```
sudo systemctl enable --now bluetooth
```

Networking uses `iwd` as its backend.

### The prompt looks wrong or the terminal opens Bash

The prompt configuration lives in `~/.zshrc`, so it only applies in Zsh.

```
getent passwd $USER | cut -d: -f7    # should end in /zsh
chsh -s /bin/zsh $USER
```

### A package cannot be found

`install.sh` validates each package list and reports missing packages. Common causes:

1. **Chaotic-AUR is not enabled.** `./install.sh` can add it after confirmation; with `--no-chaotic` the packages are built from the AUR.
2. **The pacman database is stale.** Run `sudo pacman -Sy` and retry.
3. **The package was renamed.** Open an issue with the package name so `packages/` can be updated.

### Package conflicts ("X and Y are in conflict")

The installer asks how to resolve them. The most common ones:

| Package          | Conflicts with           | Reason                                  |
| ---------------- | ------------------------ | --------------------------------------- |
| `pipewire-pulse` | `pulseaudio`             | Same role.                              |
| `wireplumber`    | `pipewire-media-session` | Direct replacement.                     |
| `7zip`           | `p7zip`                  | `7zip` already includes `p7zip`.        |
| `qt6ct-kde`      | `qt6ct`                  | The patched version replaces the other. |

`pipewire-jack` is not installed, so `jack2` is kept. If you need PipeWire's JACK compatibility, first check what depends on `jack2`. Do not run `pacman -R` blindly on conflicting packages.

### An AUR package fails to build

If you see `sudo: a terminal is required to read the password`, refresh sudo and retry:

```
sudo -v
```

Build logs are in `/tmp/rice-aur/<package>.log`.

### The script stopped unexpectedly

The installer prints the failing line, the exit code and the command. When reporting the problem, include those three details and the log (`/tmp/rice-install.log`).

To continue without installing packages:

```
./install.sh --no-packages
```

### GPU packages that no longer exist

`install.sh` skips packages from `gpu-*.txt` that are unavailable. If you see an old name (for example `libva-mesa-driver`), check your GPU list in `packages/`.

### `noctalia.lua` is regenerated with errors

Noctalia may regenerate `noctalia.lua` with a line that shadows Lua's `error()` function. The repository already fixes it and `hyprland.lua` loads it with `pcall`, so it should not affect startup.

## Rolling release

1. Read the Arch announcements before running `pacman -Syu`; Hyprland changes frequently.
2. Make a backup or snapshot before upgrading, with the tool you prefer.
3. Keep your personal configuration in a separate repository from the public clone.