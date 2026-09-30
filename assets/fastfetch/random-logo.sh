#!/usr/bin/env bash
# ~/.config/fastfetch/random-logo.sh
#
# Elige un PNG al azar de ~/.config/fastfetch/logos/ y llama a fastfetch
# usando ese logo junto con config.jsonc (los datos del sistema).
#
# Uso: alias fastfetch="~/.config/fastfetch/random-logo.sh"

set -euo pipefail

LOGO_DIR="$HOME/.config/fastfetch/logos"
CACHE_DIR="$HOME/.config/fastfetch/logos/.standardized"
CONFIG_FILE="$HOME/.config/fastfetch/config.jsonc"

# Protocolo de imagen: kitty | iterm | sixel | chafa
# kitty funciona en Kitty y WezTerm; si tu terminal no soporta protocolos
# gráficos, cambiá esto a "chafa" (renderizado ASCII/ANSI de la imagen).
LOGO_TYPE="kitty"

# Tamaño "estándar" al que se encuadra cada PNG (en píxeles, cuadrado).
# Todas tus imágenes, sin importar su tamaño o proporción original,
# quedan centradas dentro de este lienzo transparente antes de mostrarse.
STANDARD_SIZE="256x256"

if [ ! -d "$LOGO_DIR" ]; then
    echo "No existe $LOGO_DIR. Creándola..." >&2
    mkdir -p "$LOGO_DIR"
fi
mkdir -p "$CACHE_DIR"

mapfile -t LOGOS < <(find "$LOGO_DIR" -maxdepth 1 -type f -iname "*.png" | sort)

if [ "${#LOGOS[@]}" -eq 0 ]; then
    echo "No hay PNG en $LOGO_DIR. Copiá tus imágenes Frutiger Aero ahí." >&2
    exec fastfetch -c "$CONFIG_FILE" "$@"
fi

if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
    echo "Falta ImageMagick (para normalizar tamaños). Instalalo, ej: sudo pacman -S imagemagick" >&2
    RANDOM_LOGO="${LOGOS[RANDOM % ${#LOGOS[@]}]}"
    exec fastfetch --logo "$RANDOM_LOGO" --logo-type "$LOGO_TYPE" -c "$CONFIG_FILE" "$@"
fi

IM_CMD="convert"
command -v magick >/dev/null 2>&1 && IM_CMD="magick"

# Genera (o reutiliza) una versión "estandarizada" de cada original: la
# reduce/agranda para que quepa en el lienzo y la centra sobre fondo
# transparente, así todas se ven del mismo tamaño sin importar el original.
for SRC in "${LOGOS[@]}"; do
    DST="$CACHE_DIR/$(basename "$SRC")"
    if [ ! -f "$DST" ] || [ "$SRC" -nt "$DST" ]; then
        "$IM_CMD" "$SRC" \
            -resize "${STANDARD_SIZE}>" \
            -background none \
            -gravity center \
            -extent "$STANDARD_SIZE" \
            "$DST"
    fi
done

mapfile -t STD_LOGOS < <(find "$CACHE_DIR" -maxdepth 1 -type f -iname "*.png" | sort)
RANDOM_LOGO="${STD_LOGOS[RANDOM % ${#STD_LOGOS[@]}]}"

exec fastfetch \
    --logo "$RANDOM_LOGO" \
    --logo-type "$LOGO_TYPE" \
    -c "$CONFIG_FILE" \
    "$@"