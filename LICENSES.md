# Licencias de terceros

El `LICENSE` de este repositorio es MIT y cubre **solo** lo que es propio: `install.sh`, los scripts y la configuración de `~/.config`.

Los temas, iconos y cursores **no son obra propia**: se instalan desde los repositorios de Arch y no se redistribuyen aquí, salvo `home/.themes/diinki-aero` (GPL-3), que sí está incluido.

| Componente                           | Paquete                                                           | Licencia              | Ubicación                       |
| ------------------------------------ | ----------------------------------------------------------------- | --------------------- | ------------------------------- |
| **Tema del login (win7-sddm-theme)** | — (**incluido** en `assets/sddm/`)                                | MIT/GPL-3 (ver nota)  | `assets/sddm/win7-sddm-theme/`  |
| GTK theme diinki-aero                | — (incluido en `home/.themes/`)                                   | **GPL-3.0**           | `~/.themes/diinki-aero/LICENSE` |
| Iconos AwOken                        | `awoken-icons`                                                    | CC-BY-SA              | —                               |
| Cursores Vimix                       | `vimix-cursors`                                                   | GPL-3.0-or-later      | —                               |
| Cursores Comix                       | `xcursor-comix`                                                   | GPL-2.0               | —                               |
| Tema Kvantum (KvRoughGlass)          | paquete oficial `kvantum`; copia local en `home/.config/Kvantum/` | GPL-3.0-or-later      | `~/.config/Kvantum/`            |
| Nerd Fonts (76)                      | `ttf-*-nerd`, `otf-*-nerd`                                        | OFL-1.1 / MIT (varía) | —                               |
| Noctalia + greeter                   | `noctalia`, `noctalia-greeter`                                    | MIT / GPL-3           | —                               |
| Hyprland                             | `hyprland`                                                        | BSD-3                 | —                               |
| oh-my-zsh                            | clonado por `install.sh`                                          | MIT                   | —                               |
| oh-my-posh                           | `oh-my-posh`                                                      | MIT                   | —                               |

Si redistribuyes este repositorio, conserva estos avisos. Si publicas capturas de pantalla, ten en cuenta que muestran temas de terceros.

## Nota sobre `win7-sddm-theme`

El tema del login está **incluido** en `assets/sddm/` porque no existe como paquete de Arch. Su origen es <https://github.com/birbkeks/win7-sddm-theme>.

Los archivos originales son inconsistentes: su `metadata.desktop` declara `License=MIT`, pero el archivo `LICENSE` incluido contiene la GPL-3.0. Se redistribuye **tal cual**, con ambos archivos de licencia sin modificar. Si lo republicas, asume la GPL-3 (la más restrictiva) o pide al autor que lo aclare.

## English

# Third-party licenses

This repository's `LICENSE` is MIT and covers **only** original work: `install.sh`, scripts and the `~/.config` configuration.

Themes, icons and cursors are **not original work**. They are installed from Arch repositories and are not redistributed here, except for the included `home/.themes/diinki-aero` theme, which is GPL-3.

| Component                         | Package                                                           | License                | Location                        |
| --------------------------------- | ----------------------------------------------------------------- | ---------------------- | ------------------------------- |
| **Login theme (win7-sddm-theme)** | — (**included** in `assets/sddm/`)                                | MIT/GPL-3 (see note)   | `assets/sddm/win7-sddm-theme/`  |
| GTK theme diinki-aero             | — (included in `home/.themes/`)                                   | **GPL-3.0**            | `~/.themes/diinki-aero/LICENSE` |
| AwOken icons                      | `awoken-icons`                                                    | CC-BY-SA               | —                               |
| Vimix cursors                     | `vimix-cursors`                                                   | GPL-3.0-or-later       | —                               |
| Comix cursors                     | `xcursor-comix`                                                   | GPL-2.0                | —                               |
| Kvantum theme (KvRoughGlass)      | Official `kvantum` package; local copy in `home/.config/Kvantum/` | GPL-3.0-or-later       | `~/.config/Kvantum/`            |
| Nerd Fonts (76)                   | `ttf-*-nerd`, `otf-*-nerd`                                        | OFL-1.1 / MIT (varies) | —                               |
| Noctalia + greeter                | `noctalia`, `noctalia-greeter`                                    | MIT / GPL-3            | —                               |
| Hyprland                          | `hyprland`                                                        | BSD-3                  | —                               |
| oh-my-zsh                         | Cloned by `install.sh`                                            | MIT                    | —                               |
| oh-my-posh                        | `oh-my-posh`                                                      | MIT                    | —                               |

If you redistribute this repository, keep these notices. Screenshots also show third-party themes.

## Note on `win7-sddm-theme`

The login theme is **included** under `assets/sddm/` because it is not an Arch package. Its upstream is <https://github.com/birbkeks/win7-sddm-theme>.

The upstream files are inconsistent: `metadata.desktop` declares `License=MIT`, while the included `LICENSE` file contains GPL-3.0. The theme is redistributed **as-is**, with both license files unchanged. If you republish it, assume GPL-3 (the more restrictive license) or ask the author to clarify.