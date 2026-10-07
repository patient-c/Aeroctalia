# Dolphin, Kvantum e iconos KrystalSVG

Dolphin puede abrirse de tres formas distintas, y cada una necesita las variables de tema de Qt. Además, Qt6 no interpreta bien el `index.theme` de este tema y puede mostrar los iconos de `hicolor` sin avisar.

`install.sh` configura todo esto automáticamente. Para comprobarlo:

```
./tools/verify-dolphin.sh --probe
```

## Formas de abrir Dolphin

| Cómo se abre                                  | Archivo que lo configura                                       |
| --------------------------------------------- | -------------------------------------------------------------- |
| `SUPER+E` o `dolphin` en la terminal          | `~/.local/bin/dolphin` (wrapper)                               |
| Menú de Noctalia, krunner, `gio open`         | `~/.local/share/applications/org.kde.dolphin.desktop`          |
| "Mostrar en carpeta" desde el navegador       | `~/.config/systemd/user/plasma-dolphin.service.d/kvantum.conf` |

Ninguna hereda la configuración de las otras. Por eso, si Dolphin se ve sin tema solo al abrirlo desde el navegador, la causa suele ser la tercera.

Todas usan estas variables:

| Variable                     | Función                                        |
| ---------------------------- | ---------------------------------------------- |
| `QT_STYLE_OVERRIDE=kvantum`  | Estilo de los widgets (KvRoughGlass).          |
| `QT_QPA_PLATFORMTHEME=qt6ct` | Permite a Qt leer el tema de iconos.          |

`~/.config/environment.d/50-rice.conf` aplica la variable de tema a toda la sesión. Requiere **cerrar sesión y volver a entrar**:

```
systemctl --user show-environment | grep QT_QPA_PLATFORMTHEME
# si no muestra nada, falta volver a iniciar sesión
```

## El tema de iconos

KrystalSVG no es un paquete: `install.sh` lo descarga de la release de Aeroctalia, verifica el sha256 y lo extrae en `~/.local/share/icons/`. Los stubs que el upstream deja colgando vienen ya resueltos en el tarball, y `install.sh` se asegura de que `index.theme` herede de `Papirus,hicolor` (el valor del upstream apunta a un tema que no existe en Arch).

`install.sh` lo comprueba con `tools/qt-icon-probe.sh`, que mide de verdad qué tema resolvió Qt y no se fía de los metadatos del paquete. Para comprobarlo a mano:

```
./tools/qt-icon-probe.sh KrystalSVG-Plasma5up-scalable-icontheme-blackysgate.de
```

## Si algo no funciona

```
./tools/verify-dolphin.sh --probe
systemctl --user daemon-reload
./install.sh --no-packages          # regenera wrapper, .desktop, drop-in e index.theme
```

Después, cierra sesión y vuelve a entrar.

## English

# Dolphin, Kvantum and KrystalSVG icons

Dolphin can be launched in three different ways, and each one needs the Qt theme variables. In addition, Qt6 does not always parse this theme's `index.theme` correctly and may silently show `hicolor` icons instead.

`install.sh` sets all of this up automatically. To check it:

```
./tools/verify-dolphin.sh --probe
```

## Ways to launch Dolphin

| How it is launched                       | File that configures it                                        |
| ---------------------------------------- | -------------------------------------------------------------- |
| `SUPER+E` or `dolphin` in a terminal     | `~/.local/bin/dolphin` (wrapper)                               |
| Noctalia menu, krunner, `gio open`       | `~/.local/share/applications/org.kde.dolphin.desktop`          |
| "Show in folder" from a browser          | `~/.config/systemd/user/plasma-dolphin.service.d/kvantum.conf` |

None of them inherits configuration from the others. If Dolphin looks unthemed only when opened from a browser, the third one is usually the cause.

All of them use these variables:

| Variable                     | Purpose                                        |
| ---------------------------- | ---------------------------------------------- |
| `QT_STYLE_OVERRIDE=kvantum`  | Widget style (KvRoughGlass).                   |
| `QT_QPA_PLATFORMTHEME=qt6ct` | Lets Qt read the icon theme.                  |

`~/.config/environment.d/50-rice.conf` applies the theme variable to the whole session. It requires you to **log out and back in**:

```
systemctl --user show-environment | grep QT_QPA_PLATFORMTHEME
# empty output means you have not logged in again yet
```

## The icon theme

KrystalSVG is not a package: `install.sh` downloads it from the Aeroctalia release, verifies its sha256 and extracts it into `~/.local/share/icons/`. The broken stubs in the upstream are already resolved inside the tarball, and `install.sh` makes sure `index.theme` inherits from `Papirus,hicolor` (the upstream value points at a theme that does not exist on Arch).

`install.sh` checks this with `tools/qt-icon-probe.sh`, which measures which theme Qt actually resolved instead of trusting package metadata. To check it by hand:

```
./tools/qt-icon-probe.sh KrystalSVG-Plasma5up-scalable-icontheme-blackysgate.de
```

## Troubleshooting

```
./tools/verify-dolphin.sh --probe
systemctl --user daemon-reload
./install.sh --no-packages          # regenerates wrapper, .desktop, drop-in and index.theme
```

Then log out and back in.