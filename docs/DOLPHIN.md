# Dolphin, Kvantum e iconos AwOken

Dolphin puede abrirse de tres formas distintas, y cada una necesita las variables de tema de Qt. Además, Qt6 no interpreta bien el `index.theme` de AwOken y puede mostrar los iconos de `hicolor` sin avisar.

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
| `QT_QPA_PLATFORMTHEME=qt6ct` | Permite a Qt leer el tema de iconos AwOken.    |

`~/.config/environment.d/50-rice.conf` aplica la variable de tema a toda la sesión. Requiere **cerrar sesión y volver a entrar**:

```
systemctl --user show-environment | grep QT_QPA_PLATFORMTHEME
# si no muestra nada, falta volver a iniciar sesión
```

## Los iconos AwOken

El paquete `awoken-icons` declara sus directorios con `Type=scalable` (minúscula), y Qt6 no lo reconoce. Cuando eso ocurre, usa los iconos de `hicolor` sin mostrar ningún error.

`install.sh` lo corrige con un `index.theme` parcheado en `~/.local/share/icons/AwOken/` y lo regenera si el paquete se actualiza. Para comprobar qué iconos usa Qt:

```
./tools/qt-icon-probe.sh AwOken
```

## Si algo no funciona

```
./tools/verify-dolphin.sh --probe
systemctl --user daemon-reload
./install.sh --no-packages          # regenera wrapper, .desktop, drop-in e index.theme
```

Después, cierra sesión y vuelve a entrar.

## English

# Dolphin, Kvantum and AwOken icons

Dolphin can be launched in three different ways, and each one needs the Qt theme variables. In addition, Qt6 does not parse AwOken's `index.theme` correctly and may silently show `hicolor` icons instead.

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
| `QT_QPA_PLATFORMTHEME=qt6ct` | Lets Qt read the AwOken icon theme.            |

`~/.config/environment.d/50-rice.conf` applies the theme variable to the whole session. It requires you to **log out and back in**:

```
systemctl --user show-environment | grep QT_QPA_PLATFORMTHEME
# empty output means you have not logged in again yet
```

## AwOken icons

The `awoken-icons` package declares its directories with `Type=scalable` (lowercase), which Qt6 does not recognize. When that happens, Qt uses the `hicolor` icons without showing any error.

`install.sh` fixes this with a patched `index.theme` in `~/.local/share/icons/AwOken/` and regenerates it if the package is updated. To check which icons Qt is using:

```
./tools/qt-icon-probe.sh AwOken
```

## Troubleshooting

```
./tools/verify-dolphin.sh --probe
systemctl --user daemon-reload
./install.sh --no-packages          # regenerates wrapper, .desktop, drop-in and index.theme
```

Then log out and back in.