#!/usr/bin/env bash
# verify-dolphin.sh — los 3 caminos de arranque + el tema de iconos.
#
# Dolphin en esta rice no es "una app con un tema". Hay TRES procesos
# distintos que pueden abrirla, y Qt6 tiene un bug con AwOken que hace
# que los iconos caigan a hicolor EN SILENCIO.
#
# Uso (desde el repo, o copiado a PATH):
#   ./tools/verify-dolphin.sh
#   ./tools/verify-dolphin.sh --probe     # además corre la sonda Qt6
set -euo pipefail

PROBE=0
HOME_DIR="${HOME}"
for a in "$@"; do
  case "$a" in
    --probe) PROBE=1 ;;
    --home=*) HOME_DIR="${a#*=}" ;;
    -h|--help) printf '%s\n' "uso: $0 [--probe] [--home=DIR]"; exit 0 ;;
  esac
done

if [[ -t 1 ]]; then
  G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; C=$'\033[1;36m'; N=$'\033[0m'
else
  G=""; Y=""; R=""; C=""; N=""
fi
ok()   { printf '  %sok%s  %s\n' "$G" "$N" "$*"; }
warn() { printf '  %sav%s  %s\n' "$Y" "$N" "$*"; }
err()  { printf '  %s!!%s  %s\n' "$R" "$N" "$*"; }
info() { printf '      %s\n' "$*"; }

problems=0
hit() { problems=$((problems+1)); }

printf '\n%s── Dolphin: tres caminos + iconos%s\n' "$C" "$N"

# ── 1. wrapper (SUPER+E / terminal) ──────────────────────────────────────
wrap="$HOME_DIR/.local/bin/dolphin"
printf '\n%s[1/5] wrapper%s  %s\n' "$C" "$N" "$wrap"
if [[ -x "$wrap" ]]; then
  ok "existe y es ejecutable"
else
  err "no existe o no es ejecutable"
  info "sin esto, SUPER+E y 'dolphin' en la terminal van a /usr/bin/dolphin crudo"
  hit
fi
if [[ -f "$wrap" ]]; then
  grep -q 'QT_STYLE_OVERRIDE' "$wrap" \
    && ok "define QT_STYLE_OVERRIDE (Kvantum)" \
    || { err "no define QT_STYLE_OVERRIDE"; hit; }
  grep -q 'QT_QPA_PLATFORMTHEME' "$wrap" \
    && ok "define QT_QPA_PLATFORMTHEME (iconos vía qt6ct)" \
    || { err "no define QT_QPA_PLATFORMTHEME — los iconos van a hicolor"; hit; }
  grep -q '/usr/bin/dolphin' "$wrap" \
    && ok "exec al binario real (no se recicla a sí mismo)" \
    || { warn "no llama a /usr/bin/dolphin: riesgo de loop si está en PATH"; hit; }
fi
# ¿PATH lo resuelve?
PATH="$HOME_DIR/.local/bin:$PATH"
resolved="$(command -v dolphin 2>/dev/null || true)"
if [[ "$resolved" == "$wrap" ]]; then
  ok "command -v dolphin → wrapper"
elif [[ -n "$resolved" ]]; then
  warn "command -v dolphin → $resolved (no es el wrapper)"
  info "agregá ~/.local/bin al frente de PATH (environment.d/50-rice.conf)"
  hit
else
  warn "dolphin no está en PATH (el paquete no está instalado?)"
fi

# ── 2. .desktop (menú, krunner, gio) ─────────────────────────────────────
desk="$HOME_DIR/.local/share/applications/org.kde.dolphin.desktop"
printf '\n%s[2/5] .desktop%s  %s\n' "$C" "$N" "$desk"
if [[ -f "$desk" ]]; then
  ok "overlay de usuario presente"
  exec_line="$(grep -E '^Exec=' "$desk" | head -1 || true)"
  info "$exec_line"
  grep -q 'QT_STYLE_OVERRIDE' "$desk" \
    && ok "Exec lleva QT_STYLE_OVERRIDE" \
    || { err "Exec no lleva QT_STYLE_OVERRIDE"; hit; }
  grep -q 'QT_QPA_PLATFORMTHEME' "$desk" \
    && ok "Exec lleva QT_QPA_PLATFORMTHEME" \
    || { warn "Exec no lleva QT_QPA_PLATFORMTHEME (el environment.d puede cubrirlo)"; }
else
  err "falta el overlay; el menú usa el .desktop del paquete (sin Kvantum)"
  hit
fi

# ── 3. systemd drop-in (navegador → D-Bus) ───────────────────────────────
drop="$HOME_DIR/.config/systemd/user/plasma-dolphin.service.d/kvantum.conf"
printf '\n%s[3/5] D-Bus / systemd%s  %s\n' "$C" "$N" "$drop"
if [[ -f "$drop" ]]; then
  ok "drop-in presente"
  grep -q 'QT_STYLE_OVERRIDE=kvantum' "$drop" \
    && ok "Environment=QT_STYLE_OVERRIDE=kvantum" \
    || { err "el drop-in no inyecta Kvantum"; hit; }
  grep -q 'QT_QPA_PLATFORMTHEME' "$drop" \
    && ok "Environment=QT_QPA_PLATFORMTHEME (iconos en el camino D-Bus)" \
    || { err "sin QT_QPA_PLATFORMTHEME en el drop-in: 'mostrar en carpeta' sale sin AwOken"; hit; }
else
  err "sin drop-in: el navegador abre Dolphin por D-Bus y se saltea wrapper y .desktop"
  info "ese es el camino que más gente reporta como 'Dolphin se abre sin tema'"
  hit
fi

# ── 4. environment.d (sesión completa) ───────────────────────────────────
envd="$HOME_DIR/.config/environment.d/50-rice.conf"
printf '\n%s[4/5] environment.d%s  %s\n' "$C" "$N" "$envd"
if [[ -f "$envd" ]]; then
  ok "50-rice.conf presente"
  grep -q 'QT_QPA_PLATFORMTHEME=qt6ct' "$envd" \
    && ok "QT_QPA_PLATFORMTHEME=qt6ct" \
    || { err "falta QT_QPA_PLATFORMTHEME=qt6ct"; hit; }
else
  err "falta environment.d: los procesos de systemd --user no ven qt6ct"
  hit
fi
live="$(systemctl --user show-environment 2>/dev/null | grep '^QT_QPA_PLATFORMTHEME=' || true)"
if [[ "$live" == *qt6ct* ]]; then
  ok "la sesión actual ya tiene $live"
else
  warn "systemctl --user show-environment no tiene qt6ct"
  info "es lo normal hasta que cierres sesión. Hyprland sí lo exporta a SUS hijos."
  info "los que arranca systemd (Dolphin desde el navegador) NO, hasta el próximo login."
fi

# ── 5. tema de iconos AwOken / Qt6 ───────────────────────────────────────
printf '\n%s[5/5] iconos AwOken (el bug de Qt6)%s\n' "$C" "$N"
ic_sys="/usr/share/icons/AwOken"
ic_usr="$HOME_DIR/.local/share/icons/AwOken"
ic_idx=""
for i in "$ic_usr/index.theme" "$HOME_DIR/.icons/AwOken/index.theme" "$ic_sys/index.theme"; do
  [[ -f "$i" ]] && { ic_idx="$i"; break; }
done
if [[ -z "$ic_idx" ]]; then
  err "no hay index.theme de AwOken — el paquete awoken-icons no está?"
  info "    yay -S awoken-icons"
  hit
else
  ok "index.theme que manda: $ic_idx"
  bad="$(grep -c '^Type=scalable' "$ic_idx" 2>/dev/null || true)"
  bad="${bad:-0}"
  if [[ "$bad" -gt 0 ]]; then
    err "Type=scalable en minúscula ($bad dirs) — Qt6 no lo reconoce y CAE A HICOLOR"
    info "sin error, sin warning, QIcon::themeName() sigue diciendo AwOken"
    info "arreglo:  ./install.sh --no-packages"
    hit
  else
    ok "Type= es Scalable/Fixed (Qt6 lo entiende)"
  fi
  # directorios colgados
  if [[ -d "$ic_usr" ]]; then
    rel="$(sed -n 's/^Directories=//p' "$ic_idx" | tr ',' '\n' | sed 's#/.*##' | sed '/^[[:space:]]*$/d' | sort -u || true)"
    missing=0
    for sub in $rel; do
      [[ -e "$ic_usr/$sub" ]] || missing=$((missing+1))
    done
    if [[ "$missing" -gt 0 ]]; then
      err "faltan $missing symlinks de directorios en $ic_usr"
      info "el index.theme parcheado SIN los symlinks a /usr/share también cae a hicolor"
      hit
    else
      ok "directorios del tema colgados en el HOME (symlinks a /usr/share)"
    fi
    # find -L: el tema cuelga de symlink
    img="$(find -L "$ic_usr" -maxdepth 4 \( -name '*.png' -o -name '*.svg' \) -print -quit 2>/dev/null || true)"
    if [[ -z "$img" ]]; then
      err "el tema del HOME no tiene PNG/SVG (find -L no encontró nada)"
      hit
    else
      png="$(find -L "$ic_usr" -name '*.png' 2>/dev/null | wc -l)"
      ok "imágenes visibles vía symlink: $png PNG"
    fi
  else
    warn "no hay $ic_usr — Qt va a usar el index.theme del paquete (probablemente roto)"
    hit
  fi
fi

qt6ct="$HOME_DIR/.config/qt6ct/qt6ct.conf"
if grep -qE '^icon_theme=AwOken$' "$qt6ct" 2>/dev/null; then
  ok "qt6ct icon_theme=AwOken"
else
  warn "qt6ct no tiene icon_theme=AwOken"
  info "el nombre para Qt sale de acá, NO de kdeglobals"
  hit
fi

# hyprland.lua hardcoded path
hypr="$HOME_DIR/.config/hypr/hyprland.lua"
if [[ -f "$hypr" ]]; then
  if grep -qE 'fileManager = "/home/[^"]+/.local/bin/dolphin"' "$hypr"; then
    err "hyprland.lua tiene el HOME hardcodeado (de la máquina original)"
    info "cambiá a: local fileManager = os.getenv(\"HOME\") .. \"/.local/bin/dolphin\""
    hit
  else
    ok "hyprland.lua no tiene un HOME ajeno hardcodeado"
  fi
fi

if [[ $PROBE -eq 1 ]]; then
  printf '\n%s── sonda Qt6%s\n' "$C" "$N"
  here="$(cd "$(dirname "$0")" && pwd)"
  if [[ -x "$here/qt-icon-probe.sh" ]]; then
    "$here/qt-icon-probe.sh" AwOken || true
  else
    warn "no encuentro tools/qt-icon-probe.sh"
  fi
fi

echo
if [[ $problems -gt 0 ]]; then
  err "$problems cosa(s) para mirar — docs/DOLPHIN.md tiene el mapa"
  exit 1
fi
ok "los tres caminos y el tema de iconos cierran"
exit 0
