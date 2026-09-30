#!/usr/bin/env bash
# qt-icon-probe.sh — qué tema de iconos resolvió Qt6 DE VERDAD, y de qué píxeles.
#
# Por qué existe: "el tema está instalado" no dice nada. Qt6 puede no entender
# el index.theme, no encontrar ningún archivo y CAER A HICOLOR EN SILENCIO —
# sin error, sin warning, y QIcon::themeName() sigue devolviendo el nombre que
# pediste. Este script lo mide en vez de suponerlo.
#
# Uso:
#   ./tools/qt-icon-probe.sh                    # el tema que qt6ct tenga puesto
#   ./tools/qt-icon-probe.sh AwOken             # forzando un tema
#   ./tools/qt-icon-probe.sh AwOken Adwaita     # comparando varios
#
# Salida sana:
#   themeName: AwOken   index.theme: /home/…/.local/share/icons/AwOken/index.theme
#   Type= en minuscula: 0
#   VEREDICTO: los iconos vienen del tema. ✓
#
# LA FIRMA DEL BUG: themeName dice AwOken pero index.theme dice NO, o el md5 de
# "folder" es el mismo que el de hicolor. Eso significa que Qt está dibujando
# los iconos de otro tema sin avisar.
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! command -v g++ >/dev/null 2>&1; then
  echo "qt-icon-probe: hace falta g++ (paquete base-devel). Nada se midió." >&2
  echo "  sudo pacman -S --needed base-devel" >&2
  exit 1
fi
if ! pkg-config --exists Qt6Gui 2>/dev/null; then
  echo "qt-icon-probe: no encuentro Qt6Gui vía pkg-config. Nada se midió." >&2
  echo "  las cabeceras vienen con qt6-base; si no están: sudo pacman -S --needed qt6-base" >&2
  exit 1
fi

cat > "$TMP/probe.cpp" <<'CPP'
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QPixmap>
#include <QFile>
#include <QFileInfo>
#include <QCryptographicHash>
#include <QTimer>
#include <cstdio>

static int countLowercaseType(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return -1;
    int n = 0;
    while (!f.atEnd()) {
        const QByteArray line = f.readLine();
        if (line.startsWith("Type=scalable"))   // Qt6 no reconoce este valor
            ++n;
    }
    return n;
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    const QString forced = qEnvironmentVariable("PROBE_THEME");
    if (!forced.isEmpty())
        QIcon::setThemeName(forced);

    const QString resolved = QIcon::themeName();
    QString found;
    for (const QString &p : QIcon::themeSearchPaths()) {
        const QString f = p + QLatin1Char('/') + resolved + QLatin1String("/index.theme");
        if (QFileInfo::exists(f)) { found = f; break; }
    }
    printf("  themeName resuelto  : %s\n", resolved.isEmpty() ? "(VACIO)" : qPrintable(resolved));
    printf("  index.theme hallado : %s\n",
           found.isEmpty() ? "NO   <-- el tema no existe" : qPrintable(found));
    const int bad = found.isEmpty() ? -1 : countLowercaseType(found);
    if (bad >= 0)
        printf("  Type= en minuscula  : %d%s\n", bad,
               bad > 0 ? "   <-- Qt6 no lo reconoce: cae a hicolor" : "   (ok)");

    for (const QString &n : {QStringLiteral("folder"), QStringLiteral("text-plain"),
                             QStringLiteral("user-desktop"), QStringLiteral("emblem-favorite")}) {
        const QPixmap pm = QIcon::fromTheme(n).pixmap(48, 48);
        if (pm.isNull()) { printf("  48x48 %-16s NULL\n", qPrintable(n)); continue; }
        // Guardo la QImage en una variable: si la meto al hash directamente,
        // constBits() apunta a un temporal ya destruido y sale el md5 de "".
        const QImage img = pm.toImage().convertToFormat(QImage::Format_ARGB32);
        const QByteArray md = QCryptographicHash::hash(
            QByteArrayView(reinterpret_cast<const char *>(img.constBits()),
                           qsizetype(img.sizeInBytes())),
            QCryptographicHash::Md5).toHex().left(10);
        printf("  48x48 %-16s md5=%s\n", qPrintable(n), md.constData());
    }
    fflush(stdout);
    QTimer::singleShot(120, &app, [&] { app.quit(); });
    return app.exec();
}
CPP

g++ -std=c++17 -fPIC -O1 "$TMP/probe.cpp" -o "$TMP/probe" \
    $(pkg-config --cflags --libs Qt6Gui) 2>/dev/null \
  || { echo "qt-icon-probe: no pude compilar la sonda." >&2; exit 1; }

run() { PROBE_THEME="$1" "$TMP/probe" 2>/dev/null </dev/null || true; }

# hicolor es el fallback universal: sirve de referencia para saber si los iconos
# que salen son del tema pedido o del default.
fallback="$(run hicolor | awk '/48x48 folder/{print $3}' | head -1)"

status=0
if [[ $# -eq 0 ]]; then set -- ""; fi
for t in "$@"; do
  if [[ -n "$t" ]]; then printf '── forzando: %s\n' "$t"; else printf '── el tema que qt6ct tenga puesto\n'; fi
  out="$(run "$t")"
  printf '%s\n' "$out" | sed 's/^/  /'
  mine="$(printf '%s\n' "$out"  | awk '/48x48 folder/{print $3}' | head -1)"
  idx="$(printf '%s\n' "$out"   | sed -n 's/.*index.theme hallado : //p' | head -1)"
  bad="$(printf '%s\n' "$out"  | sed -n 's/.*Type= en minuscula  : //p' | head -1)"
  if [[ "$idx" == NO* ]]; then
    printf '  VEREDICTO: el tema no existe. Qt dibuja el fallback.\n'
    status=1
  elif [[ "${bad%% *}" =~ ^[0-9]+$ ]] && (( ${bad%% *} > 0 )); then
    printf '  VEREDICTO: index.theme con Type=scalable en minúscula. Qt busca .svg,\n'
    printf '             no las hay, y cae a hicolor sin avisar.\n'
    printf '             se arregla con:  ./install.sh --no-packages\n'
    status=1
  elif [[ -n "$fallback" && "$mine" == "$fallback" ]]; then
    printf '  VEREDICTO: los iconos SON los del fallback (hicolor), no los del tema.\n'
    status=1
  else
    printf '  VEREDICTO: los iconos vienen del tema. ✓\n'
  fi
  printf '\n'
done
exit $status
