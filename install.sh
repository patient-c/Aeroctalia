#!/usr/bin/env bash
# install.sh — Aeroctalia (Hyprland + Noctalia + Kvantum + KrystalSVG) en Arch
#
#   git clone https://github.com/patient-c/Aeroctalia
#   ./install.sh --dry-run
#   ./install.sh
#
# Dolphin/iconos: docs/DOLPHIN.md  ·  problemas: docs/MANUAL.md

set -euo pipefail

RICE_VERSION="1.0.1"

# Tema de iconos. Se leen de meta/krystalsvg.conf en krystalsvg_meta; se
# declaran aqui porque do_uninstall() corre mucho antes que ese paso.
KS_BASE_URL="https://github.com/patient-c/Aeroctalia/releases/download"
KS_ASSET=""; KS_SHA=""; KS_DIR=""
LANG="es"

normalize_lang() {
  local v="${1,,}"
  case "$v" in
    es|spa|es-es|es_mx|es_ar) echo "es" ;;
    en|eng|en-us|en_us) echo "en" ;;
    *) echo "" ;;
  esac
}

T() {
  local en="$1"
  local es="$2"
  if [[ "$LANG" == "en" ]]; then
    printf '%s' "$en"
  else
    printf '%s' "$es"
  fi
}

prompt_language() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    LANG="es"
    return 0
  fi

  while true; do
    printf 'Select language / Elige idioma [es/en]: '
    read -r LANG_ANSWER || LANG_ANSWER="es"
    LANG_ANSWER="${LANG_ANSWER:-es}"
    case "$(normalize_lang "$LANG_ANSWER")" in
      es|en)
        LANG="$(normalize_lang "$LANG_ANSWER")"
        printf '\n'
        return 0
        ;;
      *)
        printf '%s\n' "$(T "Invalid option. Use es or en." "Opción inválida. Usa es o en.")"
        ;;
    esac
  done
}

usage() {
  if [[ "$LANG" == "en" ]]; then
    cat <<'EOF'
install.sh — Aeroctalia (Hyprland + Noctalia + Kvantum + KrystalSVG)

Quick help:
  ./install.sh                     install with confirmation and backups
  ./install.sh --dry-run           show the plan without changing anything
  ./install.sh --yes              run without asking
  ./install.sh --verify           verify configuration without installing
  ./install.sh --restore         restore the last backup
  ./install.sh --profile=author  apply the optional author profile
  ./install.sh --profile=custom --profile-dir=/path/to/profile
                                 apply an external profile
  ./install.sh --uninstall        remove only Aeroctalia files in $HOME

Supported profiles:
  author   uses profiles/author
  custom   requires --profile-dir=PATH
  none     applies no extra profile

Options:
  --user-only                   do not touch /etc or ask for sudo
  --no-packages                 only copy the config
  --no-gpu                      do not install GPU drivers
  --no-fonts                    do not install nerd fonts
  --no-apps                     do not install extras.txt
  --no-aur                      do not build AUR packages
  --no-chaotic                  do not add Chaotic-AUR
  --copy-all                    also copy personal state/cache files
  --dm=sddm|greetd|none         display manager (default: sddm)
  --images=DIR                  copy the large fastfetch PNG set from DIR
  --home=DIR                    install into another HOME
  --version                     installer version
  -h, --help                    show this help
  --profile-help                show profile details

Safety and recovery:
  - each install creates a timestamped backup and manifest
  - if something fails, temporary changes are restored
  - pacman and Chaotic-AUR changes are reversible
  - use ./install.sh --restore to return to the previous state

Logs:
  ~/.local/state/rice-install/<date>/install.log
  and a symlink at /tmp/rice-install.log
EOF
  else
    cat <<'EOF'
install.sh — instala Aeroctalia en Arch Linux

Ayuda rápida:
  ./install.sh                 instala con confirmación y backups
  ./install.sh --dry-run       muestra el plan, no cambia nada
  ./install.sh --yes           no pregunta nada
  ./install.sh --verify        solo corre la verificación (no instala)
  ./install.sh --restore       restaura la última configuración respaldada
  ./install.sh --profile=author
                             aplica un perfil opcional localizado en profiles/author
  ./install.sh --profile=custom --profile-dir=/ruta/al/perfil
                             aplica un perfil externo sin tocar el repo base
  ./install.sh --uninstall     elimina solo los archivos de Aeroctalia en $HOME
                             (no paquetes del sistema ni configuraciones ajenas)

Perfiles soportados:
  author    usa profiles/author
  none      no aplica perfil extra
  custom    requiere --profile-dir=RUTA

Opciones:
  --user-only           no toca /etc ni pide sudo (solo ~)
  --no-packages         ya tenés todo instalado, solo copia la config
  --no-gpu              no instala drivers de video
  --no-fonts            no instala las nerd fonts
  --no-apps             no instala extras.txt
  --no-aur              no compila nada de AUR
  --no-chaotic          no agrega Chaotic-AUR; los paquetes terceros van por AUR
  --copy-all            copia también cachés/estado personal (GIMP, dconf…)
  --dm=sddm|greetd|none display manager (default: sddm)
  --images=DIR          copia el conjunto grande de PNG de fastfetch desde DIR
  --home=DIR            instala en otro HOME (para testear)
  --version             versión de este instalador
  -h, --help            muestra esta ayuda
  --profile-help        muestra ayuda específica para perfiles

Seguridad y recuperación:
  - cada instalación crea un backup con timestamp y un manifiesto
  - si hay un error, se restauran configuraciones temporales
  - los cambios de pacman y Chaotic-AUR son temporales y reversibles
  - usa ./install.sh --restore para volver al estado anterior

Logs: ~/.local/state/rice-install/<fecha>/install.log
      y un symlink en /tmp/rice-install.log
EOF
  fi
}

show_profile_help() {
  if [[ "$LANG" == "en" ]]; then
    cat <<'EOF'
Profile help:

  author
    uses the personal snapshot kept under profiles/author
    useful only if you want to mirror the author's look

  custom
    uses any profile directory passed with --profile-dir
    useful for a personal profile or external backup

  none
    installs the portable base with no extra profile overlay

Example:
  ./install.sh --profile=author
  ./install.sh --profile=custom --profile-dir=/path/to/profile
  ./install.sh --profile=none
EOF
  else
    cat <<'EOF'
Ayuda de perfiles:

  author
    usa la configuración personal guardada en profiles/author
    recomendable solo si querés replicar el look del autor

  custom
    usa cualquier carpeta de perfil que pases con --profile-dir
    útil para un perfil propio o un backup externo

  none
    instala la base portable sin ningún overlay de perfil

Ejemplo:
  ./install.sh --profile=author
  ./install.sh --profile=custom --profile-dir=/ruta/a/mi/perfil
  ./install.sh --profile=none
EOF
  fi
}

on_err() {
  local rc="$1" line="$2" cmd="$3"
  printf '\n%s!! %s%s\n' "${R:-}" "$(T "install.sh stopped unexpectedly" "install.sh se detuvo de golpe")" "${N:-}" >&2
  printf '   %s %s · %s %s\n' "$(T "line" "línea")" "$line" "$(T "exit code" "código de salida")" "$rc" >&2
  printf '   %s: %s\n' "$(T "command" "comando")" "$cmd" >&2
  printf '\n   Log: %s\n' "${LOG:-/tmp/rice-install.log}" >&2
  printf '   %s\n' "$(T "The installation is incomplete; temporary backups are being restored." "La instalación quedó incompleta; se restauran backups temporales.")" >&2
  exit "$rc"
}
trap 'on_err $? $LINENO "$BASH_COMMAND"' ERR
on_interrupt() {
  printf '\n  %s\n' "$(T "Interrupted." "Interrumpido.")" >&2
  printf '  %s\n' "$(T "Temporary files are restored and the log is kept." "Se restauran archivos temporales y se conserva el log.")" >&2
  exit 130
}
trap on_interrupt INT

restore_pacman_temp() {
  if [[ -n "${PACMAN_RESTORE_FILE:-}" && -f "${PACMAN_RESTORE_FILE}" ]]; then
    if [[ -n "${PACMAN_TEMP_CONF:-}" && -f "${PACMAN_TEMP_CONF}" ]]; then
      rm -f "${PACMAN_TEMP_CONF}" 2>/dev/null || true
    fi
    if [[ -n "${PACMAN_RESTORE_TARGET:-}" && -f "${PACMAN_RESTORE_FILE}" ]]; then
      as_root cp -a "${PACMAN_RESTORE_FILE}" "${PACMAN_RESTORE_TARGET}" 2>/dev/null || true
    fi
  fi
}

cleanup_install() {
  if [[ ${INSTALL_SUCCESS:-0} -eq 0 && ${RESTORE_MODE:-0} -eq 0 && ${VERIFY_ONLY:-0} -eq 0 && ${DRY:-0} -eq 0 ]]; then
    restore_pacman_temp
    if [[ -n "${STASH:-}" && -d "${STASH}" ]]; then
      info "$(T "Installation incomplete; backup/restore data at" "Instalación incompleta; respaldo/restauración en") ${STASH}"
    fi
  fi
  if [[ -n "${PACMAN_TEMP_CONF:-}" && -f "${PACMAN_TEMP_CONF}" ]]; then
    rm -f "${PACMAN_TEMP_CONF}" 2>/dev/null || true
  fi
}
trap 'cleanup_install' EXIT

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

DRY=0; ASSUME_YES=0; USER_ONLY=0; NO_GPU=0; NO_FONTS=0; NO_APPS=0
NO_AUR=0; NO_PKGS=0; DM=sddm; CHAOTIC=1; IMAGES=""; NEW_HOME="$HOME"
PROFILE_NAME=""; PROFILE_DIR=""; UNINSTALL=0; VERIFY_ONLY=0; COPY_ALL=0; RESTORE_MODE=0
INSTALL_SUCCESS=0; STASH=""; PACMAN_TEMP_CONF=""; PACMAN_RESTORE_FILE=""; PACMAN_RESTORE_TARGET=""; CHAOTIC_ADDED=0

confirm_action() {
  local msg="$1"
  if [[ $ASSUME_YES -eq 1 || $DRY -eq 1 ]]; then
    info "$msg"
    return 0
  fi
  local ans
  local prompt_suffix="[s/N]"
  [[ "$LANG" == "en" ]] && prompt_suffix="[y/N]"
  read -rp "  $msg $prompt_suffix " ans
  log_raw "  confirm: $msg -> ${ans:-N}"
  [[ "$ans" =~ ^[sSyY]$ ]]
}

if [[ -t 1 ]]; then
  C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'
  M=$'\033[1;35m'; B=$'\033[1;37m'; N=$'\033[0m'; DIM=$'\033[2m'
else
  C=""; G=""; Y=""; R=""; M=""; B=""; N=""; DIM=""
fi

show_install_summary() {
  local header="$(T "Aeroctalia is about to:" "Aeroctalia está a punto de:")"
  local install_txt="$(T "install" "instalar")"
  local modify_txt="$(T "modify user files in" "modificar archivos del usuario en")"
  local system_txt="$(T "modify system files in /etc" "modificar archivos del sistema en /etc")"
  local dm_txt="$(T "configure display manager" "configurar display manager")"
  local repo_txt="$(T "add external repository" "añadir repositorio externo")"
  local update_txt="$(T "update system and sync repositories with pacman -Syu" "actualizar el sistema y sincronizar repositorios con pacman -Syu")"
  local shell_txt="$(T "change the default shell to Zsh" "cambiar shell predeterminado a Zsh")"
  local services_txt="$(T "enable desktop services and themes" "habilitar servicios y temas del escritorio")"
  local continue_txt="$(T "Do you want to continue? [y/N]" "¿Deseas continuar? [s/N]")"

  printf '\n%s%s%s\n' "$Y" "$header" "$N"
  printf '  - %s %s %s\n' "$install_txt" "$(pkgs "$REPO/packages/base.txt" | wc -l)" "$(T "desktop packages" "paquetes del escritorio")"
  printf '  - %s %s\n' "$modify_txt" "$NEW_HOME"
  if [[ $USER_ONLY -eq 0 ]]; then
    printf '  - %s\n' "$system_txt"
    printf '  - %s: %s\n' "$dm_txt" "$DM"
  fi
  if [[ $CHAOTIC -eq 1 ]]; then
    printf '  - %s: Chaotic-AUR\n' "$repo_txt"
  fi
  [[ $NO_PKGS -eq 0 && $USER_ONLY -eq 0 ]] && printf '  - %s\n' "$update_txt"
  if command -v zsh >/dev/null 2>&1; then
    printf '  - %s\n' "$shell_txt"
  fi
  printf '  - %s\n' "$services_txt"
  printf '\n%s%s%s\n' "$B" "$continue_txt" "$N"
}

STEP=0
STEPS_TOTAL=12
T0=$SECONDS
LOG=""

log_raw() {
  [[ -n "${LOG:-}" ]] || return 0
  printf '%s\n' "$*" >>"$LOG" 2>/dev/null || true
}

step() {
  STEP=$((STEP+1))
  local msg
  msg="$(printf '\n%s[%d/%d] %s%s' "$M" "$STEP" "$STEPS_TOTAL" "$*" "$N")"
  printf '%s\n' "$msg"
  log_raw "[$STEP/$STEPS_TOTAL] $*"
}
say()  { printf '%s::%s %s\n' "$C" "$N" "$*"; log_raw ":: $*"; }
ok()   { printf '  %sok%s  %s\n' "$G" "$N" "$*"; log_raw "  ok  $*"; }
info() { printf '      %s\n' "$*"; log_raw "      $*"; }
warn() { printf '  %sav%s  %s\n' "$Y" "$N" "$*"; log_raw "  av  $*"; }
err()  { printf '  %s!!%s  %s\n' "$R" "$N" "$*" >&2; log_raw "  !!  $*"; }
die()  { err "$*"; exit 1; }

pkgs() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$@" 2>/dev/null | grep -vE '^[[:space:]]*$' || true; }

ask() {
  confirm_action "$1"
}

backup_manifest() {
  local kind="$1" target="$2" backup="$3" rel="$4"
  [[ -z "${STASH:-}" ]] && return 0
  printf '%s\t%s\t%s\t%s\n' "$kind" "$target" "$backup" "$rel" >> "$STASH/restore-manifest.tsv" 2>/dev/null || true
}

backup_target() {
  local target="$1" rel="$2" kind="${3:-file}"
  [[ -z "${STASH:-}" || -z "$target" ]] && return 0
  local backup="$STASH/$kind/$rel"
  mkdir -p "$(dirname "$backup")" 2>/dev/null || true
  if [[ -e "$target" || -L "$target" ]]; then
    cp -a "$target" "$backup" 2>/dev/null || true
    backup_manifest "$kind" "$target" "$backup" "$rel"
  fi
}

restore_latest_backup() {
  local manifest="${1:-${STASH:-}/restore-manifest.tsv}"
  if [[ ! -f "$manifest" ]]; then
    warn "$(T "No backup manifest was found to restore." "No encontré un manifiesto de respaldo para restaurar.")"
    return 1
  fi
  local kind target backup rel
  while IFS=$'\t' read -r kind target backup rel; do
    [[ -z "$kind" || -z "$target" || -z "$backup" ]] && continue
    [[ -e "$backup" ]] || continue
    mkdir -p "$(dirname "$target")" 2>/dev/null || true
    if [[ -d "$backup" ]]; then
      rm -rf "$target" 2>/dev/null || true
      cp -a "$backup" "$target" 2>/dev/null || true
    else
      cp -a "$backup" "$target" 2>/dev/null || true
    fi
  done < "$manifest"
  ok "$(T "Restore completed from" "Restauración finalizada desde") $manifest"
  return 0
}

as_root() {
  if   [[ $EUID -eq 0 ]]; then "$@"
  elif [[ $DRY -eq 1 ]]; then info "[dry-run] sudo $*"; return 0
  else sudo "$@"
  fi
}

run() {
  if [[ $DRY -eq 1 ]]; then info "[dry-run] $*"; return 0; fi
  "$@"
}

skip_home() {
  local rel="$1" pat dir
  [[ $COPY_ALL -eq 1 ]] && return 1
  [[ -f "$REPO/packages/skip-home.txt" ]] || return 1
  while IFS= read -r pat || [[ -n "$pat" ]]; do
    pat="${pat%%#*}"
    pat="${pat#"${pat%%[![:space:]]*}"}"
    pat="${pat%"${pat##*[![:space:]]}"}"
    [[ -z "$pat" ]] && continue
    if [[ "$pat" == */ ]]; then
      dir="${pat%/}"
      [[ "$rel" == "$dir" || "$rel" == "$dir"/* ]] && return 0
    else
      case "$rel" in $pat) return 0 ;; esac
    fi
  done < "$REPO/packages/skip-home.txt"
  return 1
}

banner() {
  printf '\n'
  printf '%s  ┌─────────────────────────────────────────────┐%s\n' "$C" "$N"
  printf '%s  │%s  Aeroctalia  %s%-28s%s   │%s\n'             "$C" "$B" "$DIM" "v$RICE_VERSION" "$C" "$N"
  printf '%s  │%s  Hyprland · Noctalia · Frutiger Aero        %s│%s\n' "$C" "$N" "$C" "$N"
  printf '%s  └─────────────────────────────────────────────┘%s\n' "$C" "$N"
}

# ── args ────────────────────────────────────────────────────────────────
prompt_language

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY=1 ;;
    --yes|-y)      ASSUME_YES=1 ;;
    --user-only)   USER_ONLY=1 ;;
    --no-gpu)      NO_GPU=1 ;;
    --no-fonts)    NO_FONTS=1 ;;
    --no-apps)     NO_APPS=1 ;;
    --no-aur)      NO_AUR=1 ;;
    --no-packages) NO_PKGS=1 ;;
    --no-chaotic)  CHAOTIC=0 ;;
    --copy-all)    COPY_ALL=1 ;;
    --verify)      VERIFY_ONLY=1 ;;
    --restore)     RESTORE_MODE=1 ;;
    --profile=*)   PROFILE_NAME="${1#*=}" ;;
    --profile-dir=*) PROFILE_DIR="${1#*=}" ;;
    --uninstall)   UNINSTALL=1 ;;
    --dm=*)        DM="${1#*=}"
                   case "$DM" in sddm|greetd|none) ;; *) die "$(T "--dm: choose sddm, greetd or none" "--dm: elige sddm, greetd o none")" ;; esac ;;
    --images=*)    IMAGES="${1#*=}" ;;
    --home=*)      NEW_HOME="${1#*=}" ;;
    --version|-v)  echo "Aeroctalia install.sh $RICE_VERSION"; exit 0 ;;
    --profile-help) show_profile_help; exit 0 ;;
    -h|--help)     usage; exit 0 ;;
    *) die "$(T "Unknown option: $1 (display manager: --dm=sddm|greetd|none)" "Opción desconocida: $1 (gestor de inicio: --dm=sddm|greetd|none)")" ;;
  esac
  shift
done

banner

# ══════════════════════════════════════════════════════ 1. Preflight ═════
step "$(T "Preflight" "Comprobaciones previas")"

[[ -r /etc/os-release ]] || die "$(T "This does not look like Linux." "Esto no parece Linux.")"
# shellcheck disable=SC1091
source /etc/os-release 2>/dev/null || true
[[ "${ID:-}" == "arch" || "${ID_LIKE:-}" == *arch* ]] || \
  die "$(T "This installer is for Arch Linux (this system is ${PRETTY_NAME:-unknown})." "Este instalador es para Arch Linux (este sistema es ${PRETTY_NAME:-desconocido}).")"
command -v pacman >/dev/null || die "$(T "pacman is missing." "Falta pacman.")"
ok "Arch Linux ($(uname -r))"

if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
  UH="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  [[ -n "$UH" ]] && NEW_HOME="$UH"
  ok "$(T "Running as root; installing to" "Ejecutando como root; se instalará en") $NEW_HOME"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
STASH="${XDG_STATE_HOME:-$NEW_HOME/.local/state}/rice-install/$STAMP"
mkdir -p "$STASH" 2>/dev/null || mkdir -p "/tmp/rice-install/$STAMP"
[[ -d "$STASH" ]] || STASH="/tmp/rice-install/$STAMP"
LOG="$STASH/install.log"
: >"$LOG" 2>/dev/null || LOG="/tmp/rice-install.log"
ln -sfn "$LOG" /tmp/rice-install.log 2>/dev/null || true
info "Log: $LOG"

ORIGIN_HOME="$NEW_HOME"
if [[ -f "$REPO/meta/origin.txt" ]]; then
  ORIGIN_HOME="$(sed -n 's/^ORIGIN_HOME=//p' "$REPO/meta/origin.txt" | head -1)"
  [[ -z "$ORIGIN_HOME" ]] && ORIGIN_HOME="$NEW_HOME"
fi
if [[ "$ORIGIN_HOME" != "$NEW_HOME" ]]; then
  ok "$(T "Rewriting paths from" "Reescribiendo rutas de") $ORIGIN_HOME → $NEW_HOME"
fi

if [[ -d "$NEW_HOME/.config/hypr" && $UNINSTALL -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  warn "$(T "A Hyprland config already exists in" "Ya existe una configuración de Hyprland en") $NEW_HOME — $(T "files may be overwritten" "algunos archivos podrían sobrescribirse")"
  warn "$(T "Existing files will be backed up to" "Los archivos existentes se respaldarán en") $STASH"
fi

avail_gb="$(df -BG --output=avail "$NEW_HOME" 2>/dev/null | tail -1 | tr -dc '0-9' || true)"
avail_gb="${avail_gb:-0}"
if [[ "$avail_gb" -gt 0 && "$avail_gb" -lt 5 ]]; then
  warn "$(T "Only ${avail_gb}G free; fonts and AUR builds need disk space." "Solo hay ${avail_gb}G libres; las fuentes y compilaciones AUR necesitan espacio.")"
elif [[ "$avail_gb" -eq 0 ]]; then
  info "$(T "Could not check free space for" "No se pudo comprobar el espacio libre de") $NEW_HOME; $(T "continuing anyway" "se continúa de todos modos")"
fi

need_sudo=0
if [[ $USER_ONLY -eq 0 && $EUID -ne 0 && $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  need_sudo=1
fi
if [[ $need_sudo -eq 1 ]]; then
  if sudo -v 2>/dev/null; then ok "$(T "sudo is available" "sudo está disponible")"
  else die "$(T "sudo is required (or use --user-only / --verify)." "Se necesita sudo (o usa --user-only / --verify).")"; fi
elif [[ $DRY -eq 1 ]]; then
  info "$(T "[dry-run] sudo will not be requested" "[dry-run] no se solicitará sudo")"
fi

# GPU por vendor ID, no por el nombre comercial.
GPU_KIND="ninguna"
gpu_raw="$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d controller|display' || true)"
[[ -z "$gpu_raw" ]] && gpu_raw="$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display' || true)"
gpu_ids="$(grep -oE '\[[0-9a-f]{4}:[0-9a-f]{4}\]' <<<"$gpu_raw" | tr -d '[]' | cut -d: -f1 | sort -u | tr '\n' ' ' || true)"
has_intel=0; has_amd=0; has_nv=0
[[ "$gpu_ids" == *8086* ]] && has_intel=1
[[ "$gpu_ids" == *1002* ]] && has_amd=1
[[ "$gpu_ids" == *10de* ]] && has_nv=1
if [[ $has_nv -eq 1 && $has_intel -eq 1 ]]; then GPU_KIND="hybrid-intel"
elif [[ $has_intel -eq 1 ]]; then GPU_KIND="intel"
elif [[ $has_amd -eq 1  ]]; then GPU_KIND="amd"
elif [[ $has_nv -eq 1   ]]; then GPU_KIND="nvidia"
else
  if   grep -qiE 'nvidia'                <<<"$gpu_raw"; then GPU_KIND="nvidia"
  elif grep -qiE 'radeon|advanced micro|ati ' <<<"$gpu_raw"; then GPU_KIND="amd"
  elif grep -qiE 'intel'                 <<<"$gpu_raw"; then GPU_KIND="intel"
  fi
fi
info "$(T "GPU detected:" "GPU detectada:") $GPU_KIND"
info "  ${gpu_raw:-$(T "no lspci output" "sin salida de lspci")}"
[[ $GPU_KIND == "ninguna" ]] && warn "$(T "GPU not detected; drivers will not be installed. Install them manually." "No se detectó la GPU; no se instalarán drivers. Instálalos manualmente.")"

chao_n=0; [[ -f "$REPO/packages/chaotic.txt" ]] && chao_n="$(pkgs "$REPO/packages/chaotic.txt" | wc -l)"
AUR_LOG="/tmp/rice-aur"
AUR_HELPER=""
command -v yay >/dev/null  && AUR_HELPER="yay"
[[ -z "$AUR_HELPER" ]] && command -v paru >/dev/null && AUR_HELPER="paru"

# ══════════════════════════════════════════════════════ 2. Plan ══════════
step "$(T "Plan" "Plan")"
printf '     %-28s %s\n' "$(T "version" "versión")" "install.sh $RICE_VERSION"
printf '     %-28s %s\n' "$(T "destination" "destino")" "$NEW_HOME"
printf '     %-28s %s\n' "Log" "$LOG"

if [[ $VERIFY_ONLY -eq 1 ]]; then
  printf '     %-28s %s\n' "$(T "mode" "modo")" "$(T "verification only" "solo verificación")"
elif [[ $UNINSTALL -eq 1 ]]; then
  printf '     %-28s %s\n' "$(T "mode" "modo")" "$(T "remove Aeroctalia files from" "quitar archivos de Aeroctalia de") $NEW_HOME"
else
  printf '     %-28s %s\n' "$(T "base packages" "paquetes base")" "$(pkgs "$REPO/packages/base.txt" | wc -l)"
  [[ $NO_GPU -eq 0 && -f "$REPO/packages/gpu-$GPU_KIND.txt" ]] && \
    printf '     %-28s %s (%s)\n' "drivers" "$(pkgs "$REPO/packages/gpu-$GPU_KIND.txt" | wc -l)" "$GPU_KIND"
  [[ $NO_FONTS -eq 0 ]] && printf '     %-28s %s\n' "$(T "fonts" "fuentes")" "$(pkgs "$REPO/packages/fuentes.txt" | wc -l)"
  [[ $NO_APPS  -eq 0 ]] && printf '     %-28s %s\n' "$(T "extras" "extras")" "$(pkgs "$REPO/packages/extras.txt"  | wc -l)"
  printf '     %-28s %s\n' "Chaotic-AUR" "$([[ $CHAOTIC -eq 1 ]] && T "yes ($chao_n packages)" "sí ($chao_n paquetes)" || T "no ($chao_n will use AUR)" "no ($chao_n van por AUR)")"
  [[ $NO_AUR -eq 0 ]] && printf '     %-28s %s\n' "AUR" "$(pkgs "$REPO/packages/aur.txt" | wc -l)"
  [[ $NO_PKGS -eq 1 ]] && printf '     %-28s %s\n' "$(T "packages" "paquetes")" "NO (--no-packages)"
  printf '     %-28s %s\n' "$(T "config files" "archivos de config")" "$(find "$REPO/home" -mindepth 1 \( -type f -o -type l \) 2>/dev/null | wc -l)"
  printf '     %-28s %s\n' "skip-home" "$([[ $COPY_ALL -eq 1 ]] && T "disabled (--copy-all)" "desactivado (--copy-all)" || T "enabled (caches/GIMP/dconf)" "activo (cachés/GIMP/dconf)")"
  [[ $USER_ONLY -eq 1 ]] && printf '     %-28s %s\n' "/etc" "NO (--user-only)"
  printf '     %-28s %s\n' "$(T "display manager" "gestor de inicio")" "$DM"
fi
[[ $DRY -eq 1 ]] && say "$(T "DRY RUN: no changes will be made" "DRY-RUN: no se modificará nada")"

# ── uninstall / verify early exits ───────────────────────────────────────
# ══════════════════════════════════════════════════════ KrystalSVG ═══════
# El tema de iconos va como asset de nuestra propia release, no como paquete:
# son 477 MB descomprimido y no esta en ningun repositorio ni en la AUR. Se
# verifica por sha256 y solo se descarga una vez.
#
# El tarball ya lleva resueltos los stubs (el upstream usa nombres que no
# existen y dejaba ~40 iconos de apps modernas vacios). Aqui solo se asegura
# Inherits= y la cache de GTK.


krystalsvg_meta() {
  local f="$REPO/meta/krystalsvg.conf"
  [[ -f $f ]] || return 1
  KS_ASSET="$(sed -n 's/^ASSET=//p' "$f" | head -1 | tr -d '\r')"
  KS_SHA="$(sed -n 's/^SHA256=//p' "$f" | head -1 | tr -d '[:space:]')"
  KS_DIR="$(sed -n 's/^DIR=//p' "$f" | head -1 | tr -d '\r')"
  [[ -n $KS_ASSET && -n $KS_SHA && -n $KS_DIR ]]
}

krystalsvg_patch() {
  # OJO: en una sola linea NO, "local d=... idx=$d/index.theme" expande $d antes
  # de asignarlo y idx se queda sin el nombre del tema. Bash expande todos los
  # argumentos de local antes de ejecutar ninguno.
  local d="$NEW_HOME/.local/share/icons/$KS_DIR"
  local idx="$d/index.theme"
  local indent
  # OJO: en este index.theme las claves van CON sangria ("  Inherits=..."), asi
  # que un '^Inherits=' no casa y el parche no haria nada.
  # Solo se guarda la sangria, nunca la clave, o saldria
  # "Inherits=Inherits=Papirus,hicolor".
  indent="$(sed -n 's/^\([[:space:]]*\)[Ii]nherits=.*/\1/p' "$idx" 2>/dev/null | head -1)"
  if grep -qEi '^[[:space:]]*inherits=.*bullschit' "$idx" 2>/dev/null; then
    cp -a "$idx" "$idx.aeroctalia.bak" 2>/dev/null || true
    if sed -i -E "s|^[[:space:]]*[Ii]nherits=.*|${indent}Inherits=Papirus,hicolor|" "$idx" 2>/dev/null; then
      ok "$(T "KrystalSVG: Inherits=Papirus,hicolor" "KrystalSVG: Inherits=Papirus,hicolor")"
      info "    $(T "the upstream value pointed at a theme that does not exist on Arch" "el valor del upstream apuntaba a un tema que no existe en Arch")"
    else
      warn "$(T "Could not patch Inherits in KrystalSVG" "No se pudo parchear Inherits en KrystalSVG")"
    fi
  else
    ok "$(T "KrystalSVG: Inherits already correct" "KrystalSVG: Inherits ya correcto")"
  fi
  [[ $USER_ONLY -eq 1 ]] || as_root gtk-update-icon-cache -f -t "$d" >/dev/null 2>&1 || true
}

krystalsvg_fetch() {
  local url="$KS_BASE_URL/v$RICE_VERSION/$KS_ASSET" tmp got
  tmp="$(mktemp -d 2>/dev/null)" || { warn "$(T "Could not create a temp dir" "No se pudo crear un directorio temporal")"; return 1; }
  info "$(T "Downloading" "Descargando") $url"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 2 --connect-timeout 20 -o "$tmp/$KS_ASSET" "$url" >/dev/null 2>&1 || {
      rm -rf "$tmp"; warn "$(T "Download failed" "Falló la descarga")"; return 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q --tries=2 -O "$tmp/$KS_ASSET" "$url" >/dev/null 2>&1 || {
      rm -rf "$tmp"; warn "$(T "Download failed" "Falló la descarga")"; return 1; }
  else
    rm -rf "$tmp"
    warn "$(T "Neither curl nor wget is available" "No hay curl ni wget")"
    return 1
  fi

  got="$(sha256sum "$tmp/$KS_ASSET" 2>/dev/null | cut -d' ' -f1)"
  if [[ "$got" != "$KS_SHA" ]]; then
    rm -rf "$tmp"
    warn "$(T "sha256 mismatch; not installing the icon theme" "sha256 no coincide; no se instala el tema de iconos")"
    info "    $(T "expected" "esperado"): $KS_SHA"
    info "    $(T "got" "obtenido"):     ${got:-?}"
    return 1
  fi
  ok "$(T "sha256 verified" "sha256 verificado")"

  mkdir -p "$NEW_HOME/.local/share/icons" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  if ! tar --zstd -xf "$tmp/$KS_ASSET" -C "$NEW_HOME/.local/share/icons" 2>/dev/null; then
    # zstd puede faltar si se instaló con --no-packages
    if ! zstd -d -q -c "$tmp/$KS_ASSET" 2>/dev/null | tar -xf - -C "$NEW_HOME/.local/share/icons" 2>/dev/null; then
      rm -rf "$tmp"; warn "$(T "Could not extract the icon theme (missing zstd?)" "No se pudo extraer el tema (¿falta zstd?)")"; return 1;
    fi
  fi
  rm -rf "$tmp"
  [[ -d "$NEW_HOME/.local/share/icons/$KS_DIR" ]] || {
    warn "$(T "Archive did not contain" "El archivo no traía") $KS_DIR/"; return 1; }
  return 0
}

install_krystalsvg() {
  local d="$NEW_HOME/.local/share/icons"
  if ! krystalsvg_meta; then
    warn "$(T "meta/krystalsvg.conf is missing; skipping the icon theme" "Falta meta/krystalsvg.conf; se omite el tema de iconos")"
    return 0
  fi
  if [[ -f "$d/$KS_DIR/index.theme" ]]; then
    if [[ $DRY -eq 0 ]]; then
      ok "$(T "KrystalSVG already installed" "KrystalSVG ya instalado")"
      krystalsvg_patch
    else
      info "$(T "[dry-run] KrystalSVG is already installed" "[dry-run] KrystalSVG ya está instalado")"
    fi
    return 0
  fi
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would download" "[dry-run] se descargaría") $KS_BASE_URL/v$RICE_VERSION/$KS_ASSET"
    info "$(T "[dry-run] then extract, verify the sha256 and patch Inherits" "[dry-run] luego extraer, verificar el sha256 y parchear Inherits")"
    return 0
  fi
  krystalsvg_fetch && krystalsvg_patch && \
    ok "$(T "KrystalSVG installed" "KrystalSVG instalado")"
}


# Genera los ficheros de color a partir de la paleta de Noctalia, para que una
# instalacion recien hecha ya tenga prompt, ls, grep y bat con color sin
# depender del hook. Es best-effort: si Noctalia todavia no ha escrito
# settings.toml, el .zshrc los regenera en el siguiente arranque.
rice_generate_themes() {
  local pal="$NEW_HOME/.local/bin/noctalia-animfetch-palette"
  local thm="$NEW_HOME/.local/bin/noctalia-shell-theme"
  local n=0

  [[ -x $pal && -x $thm ]] || return 0
  chmod +x "$NEW_HOME/.local/bin/noctalia-animfetch-palette" \
            "$NEW_HOME/.local/bin/noctalia-shell-theme" 2>/dev/null || true

  HOME="$NEW_HOME" "$pal" >/dev/null 2>&1 && n=$((n+1))
  if HOME="$NEW_HOME" "$thm" >/dev/null 2>&1; then
    ok "$(T "Colours generated from the Noctalia palette (prompt, ls, grep, bat)" "Colores generados desde la paleta de Noctalia (prompt, ls, grep, bat)")"
    [[ $n -eq 1 ]] && ok "$(T "palette.json written" "palette.json escrito")"
  else
    warn "$(T "Could not generate the colours yet" "No se pudieron generar los colores todavia")"
    info "    $(T "they are regenerated on the next login or wallpaper change" "se regeneran en el proximo inicio de sesion o al cambiar el fondo")"
  fi
}

do_uninstall() {
  step "$(T "Remove Aeroctalia files" "Quitar archivos de Aeroctalia")"
  info "$(T "Packages are NOT removed (pacman/yay). Only files under" "NO se desinstalan paquetes (pacman/yay). Solo archivos en") $NEW_HOME."
  ask "$(T "Remove the Dolphin wrapper, drop-in, environment.d file and patched index.theme?" "¿Quitar el wrapper de Dolphin, drop-in, environment.d y el index.theme parcheado?")" || { say "$(T "Cancelled" "Cancelado")"; exit 0; }
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would remove:" "[dry-run] se quitaría:")"
    info "  ~/.local/bin/dolphin"
    info "  ~/.local/share/applications/org.kde.dolphin.desktop"
    info "  ~/.config/systemd/user/plasma-dolphin.service.d/"
    info "  ~/.config/environment.d/50-rice.conf"
    info "  ~/.local/share/icons/$KS_DIR/index.theme  ($(T "only if marked # rice:" "solo si tiene la marca # rice:"))"
    return 0
  fi
  rm -f "$NEW_HOME/.local/bin/dolphin"
  rm -f "$NEW_HOME/.local/share/applications/org.kde.dolphin.desktop"
  rm -rf "$NEW_HOME/.config/systemd/user/plasma-dolphin.service.d"
  rm -f "$NEW_HOME/.config/environment.d/50-rice.conf"
  krystalsvg_meta 2>/dev/null || true
  local idx="$NEW_HOME/.local/share/icons/$KS_DIR/index.theme"
  if [[ -f "$idx" ]] && head -1 "$idx" 2>/dev/null | grep -q '^# rice:'; then
    rm -f "$idx"
    ok "$(T "Removed the patched index.theme" "Se quitó el index.theme parcheado")"
  fi
  systemctl --user daemon-reload 2>/dev/null || true
  ok "$(T "Dolphin/icon files removed from" "Archivos de Dolphin/iconos quitados de") $NEW_HOME"
  info "$(T "The rest of ~/.config (Hyprland, Noctalia, Kvantum, etc.) was left untouched:" "El resto de ~/.config (Hyprland, Noctalia, Kvantum, etc.) se dejó intacto:")"
  info "  $(T "They are your config. Remove them manually or restore a backup:" "Es tu configuración. Bórrala manualmente o restaura un respaldo:")"
  info "  ls ${XDG_STATE_HOME:-$NEW_HOME/.local/state}/rice-install/"
}

if [[ $UNINSTALL -eq 1 ]]; then
  do_uninstall
  echo
  say "$(T "Removal complete. Elapsed: ${SECONDS}s" "Desinstalación terminada. Tiempo: ${SECONDS}s")"
  INSTALL_SUCCESS=1
  exit 0
fi

if [[ $RESTORE_MODE -eq 1 ]]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"
  STASH="${XDG_STATE_HOME:-$NEW_HOME/.local/state}/rice-install/restore-$STAMP"
  mkdir -p "$STASH" 2>/dev/null || STASH="/tmp/rice-install/restore-$STAMP"
  LOG="$STASH/install.log"
  : >"$LOG"
  say "$(T "Restore mode: searching for the latest backup in" "Modo de restauración: buscando el último respaldo en") ${XDG_STATE_HOME:-$NEW_HOME/.local/state}/rice-install"
  last_dir="$(find "${XDG_STATE_HOME:-$NEW_HOME/.local/state}/rice-install" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)"
  if [[ -z "$last_dir" ]]; then
    warn "$(T "No previous backups were found." "No se encontraron respaldos anteriores.")"
    exit 1
  fi
  if [[ -f "$last_dir/restore-manifest.tsv" ]]; then
    restore_latest_backup "$last_dir/restore-manifest.tsv"
  else
    warn "$(T "The previous backup is incomplete and has no manifest. Nothing will be restored for safety." "El respaldo anterior está incompleto y no tiene manifiesto. Por seguridad, no se restaurará nada.")"
    exit 1
  fi
  exit 0
fi

show_install_summary
if ! confirm_action "$(T "Continue with these changes?" "¿Continuar con estos cambios?")"; then
  say "$(T "Cancelled" "Cancelado")"
  INSTALL_SUCCESS=1
  exit 0
fi

if [[ $VERIFY_ONLY -eq 1 ]]; then
  # salta al bloque de verificación al final: marcamos para no instalar
  NO_PKGS=1
  USER_ONLY=1
  DRY=1
  info "$(T "--verify mode: nothing will be written; configuration will only be inspected." "Modo --verify: no se escribirá nada; solo se inspeccionará la configuración.")"
fi

# ══════════════════════════════════════════════════════ 3. chaotic-aur ═══
step "$(T "Third-party repositories (Chaotic-AUR)" "Repositorios de terceros (Chaotic-AUR)")"

if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
elif [[ $RESTORE_MODE -eq 1 ]]; then
  info "$(T "Restore mode: pacman and external repositories are untouched." "Modo de restauración: no se modifican pacman ni los repositorios externos.")"
elif [[ $NO_PKGS -eq 1 ]]; then
  info "$(T "Skipped (--no-packages)" "Omitido (--no-packages)")"
elif [[ $CHAOTIC -eq 0 ]]; then
  info "$(T "Chaotic-AUR disabled (--no-chaotic): the $chao_n third-party packages" "Chaotic-AUR desactivado (--no-chaotic): los $chao_n paquetes de terceros")"
  info "$(T "will be built from the AUR with ${AUR_HELPER:-yay}. Slower; pacman.conf is untouched." "se compilarán desde AUR con ${AUR_HELPER:-yay}. Es más lento y no modifica pacman.conf.")"
elif grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
  ok "$(T "Chaotic-AUR is already configured" "Chaotic-AUR ya está configurado")"
elif [[ $USER_ONLY -eq 1 ]]; then
  warn "$(T "Root access is required to add Chaotic-AUR (--user-only skips this step)." "Se necesita acceso root para agregar Chaotic-AUR (--user-only omite este paso).")"
  CHAOTIC=0
else
  info "$(T "An external repository will be added: Chaotic-AUR" "Se agregará un repositorio externo: Chaotic-AUR")"
  info "$(T "This modifies /etc/pacman.conf and uses an unofficial package source." "Esto modifica /etc/pacman.conf y usa una fuente no oficial de paquetes.")"
  if ! confirm_action "$(T "Continue with Chaotic-AUR?" "¿Continuar con Chaotic-AUR?")"; then
    warn "$(T "Chaotic-AUR was declined; packages will use the AUR instead." "Se rechazó Chaotic-AUR; los paquetes usarán AUR en su lugar.")"
    CHAOTIC=0
  else
    if [[ $DRY -eq 0 ]]; then
      key_output=""
      if ! key_output="$(as_root pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>&1)"; then
        warn "$(T "Could not retrieve the Chaotic-AUR signing key; falling back to the AUR." "No se pudo obtener la clave de Chaotic-AUR; se usará AUR como alternativa.")"
        err "$key_output"
        CHAOTIC=0
      elif ! key_output="$(as_root pacman-key --lsign-key 3056513887B78AEB 2>&1)"; then
        warn "$(T "Could not locally sign the Chaotic-AUR key; falling back to the AUR." "No se pudo firmar localmente la clave de Chaotic-AUR; se usará AUR como alternativa.")"
        err "$key_output"
        CHAOTIC=0
      elif ! key_output="$(as_root pacman -U --noconfirm \
          'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
          'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>&1)"; then
        warn "$(T "Could not install the Chaotic-AUR keyring/mirrorlist; falling back to the AUR." "No se pudieron instalar keyring/mirrorlist de Chaotic-AUR; se usará AUR como alternativa.")"
        err "$key_output"
        CHAOTIC=0
      else
        PACMAN_RESTORE_TARGET="/etc/pacman.conf"
        PACMAN_RESTORE_FILE="${STASH}/pacman.conf.bak"
        if ! as_root cp -a /etc/pacman.conf "$PACMAN_RESTORE_FILE"; then
          die "$(T "Could not back up /etc/pacman.conf; refusing to modify it." "No se pudo respaldar /etc/pacman.conf; no se modificará.")"
        fi
        if printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' \
             | as_root tee -a /etc/pacman.conf >/dev/null 2>&1 \
           && grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
          CHAOTIC_ADDED=1
          ok "$(T "Chaotic-AUR keyring and mirrorlist installed; repository configured." "Keyring y mirrorlist de Chaotic-AUR instalados; repositorio configurado.")"
        else
          restore_pacman_temp
          PACMAN_RESTORE_FILE=""
          PACMAN_RESTORE_TARGET=""
          die "$(T "Could not configure Chaotic-AUR in /etc/pacman.conf." "No se pudo configurar Chaotic-AUR en /etc/pacman.conf.")"
        fi
      fi
    else
      info "$(T "[dry-run] would retrieve/sign the Chaotic-AUR key, install its keyring/mirrorlist, then configure pacman.conf." "[dry-run] se obtendría/firmaría la clave de Chaotic-AUR, se instalarían keyring/mirrorlist y luego se configuraría pacman.conf.")"
    fi
  fi
fi

if [[ $VERIFY_ONLY -eq 0 && $RESTORE_MODE -eq 0 && $NO_PKGS -eq 0 && $USER_ONLY -eq 0 ]]; then
  info "$(T "Preparing repositories and package managers before package lists." "Preparando repositorios y gestores antes de procesar las listas de paquetes.")"
  if [[ $DRY -eq 1 ]]; then
    info "[dry-run] sudo pacman -Syu --noconfirm"
    info "[dry-run] sudo pacman -S --needed --noconfirm git base-devel"
    if [[ $NO_AUR -eq 0 && -s "$REPO/packages/aur.txt" && -z "$AUR_HELPER" ]] \
       || [[ $CHAOTIC -eq 0 && $chao_n -gt 0 && -z "$AUR_HELPER" ]]; then
      info "$(T "[dry-run] build yay before installing AUR packages" "[dry-run] compilar yay antes de instalar paquetes AUR")"
    fi
  else
    sync_output=""
    if ! sync_output="$(as_root pacman -Syu --noconfirm 2>&1)"; then
      if [[ $CHAOTIC_ADDED -eq 1 ]]; then
        warn "$(T "Chaotic-AUR sync failed; restoring pacman.conf and retrying official repositories." "Falló la sincronización de Chaotic-AUR; se restaura pacman.conf y se reintentan los repositorios oficiales.")"
        err "$sync_output"
        restore_pacman_temp
        PACMAN_RESTORE_FILE=""
        PACMAN_RESTORE_TARGET=""
        CHAOTIC_ADDED=0
        CHAOTIC=0
        if ! sync_output="$(as_root pacman -Syu --noconfirm 2>&1)"; then
          err "$sync_output"
          die "$(T "pacman could not synchronize official repositories. No package installation was attempted." "pacman no pudo sincronizar los repositorios oficiales. No se intentó instalar paquetes.")"
        fi
      else
        err "$sync_output"
        die "$(T "pacman could not synchronize repositories. No package installation was attempted." "pacman no pudo sincronizar los repositorios. No se intentó instalar paquetes.")"
      fi
    fi
    ok "$(T "Repositories synchronized and system updated." "Repositorios sincronizados y sistema actualizado.")"

    aur_required=0
    [[ $NO_AUR -eq 0 && -s "$REPO/packages/aur.txt" ]] && aur_required=1
    [[ $CHAOTIC -eq 0 && $chao_n -gt 0 ]] && aur_required=1
    if [[ $aur_required -eq 1 && -z "$AUR_HELPER" ]]; then
      info "$(T "Installing AUR build prerequisites." "Instalando dependencias para compilar paquetes AUR.")"
      prereq_output=""
      if ! prereq_output="$(as_root pacman -S --needed --noconfirm git base-devel 2>&1)"; then
        err "$prereq_output"
        die "$(T "Could not install git/base-devel; stopping before package lists." "No se pudieron instalar git/base-devel; se detiene antes de procesar las listas.")"
      fi
      if [[ $EUID -eq 0 ]]; then
        die "$(T "Build yay as a regular user, not root; rerun install.sh without sudo." "Compila yay como usuario normal, no como root; vuelve a ejecutar install.sh sin sudo.")"
      fi
      if ! sudo -v; then
        die "$(T "sudo authorization is required to build and install yay." "Se necesita autorización sudo para compilar e instalar yay.")"
      fi
      export GOCACHE="${GOCACHE:-$(mktemp -d -t go-build-XXXXXX)}"
      export GOPATH="${GOPATH:-$(mktemp -d -t go-path-XXXXXX)}"
      rm -rf /tmp/yay-build
      info "$(T "Building yay before processing package lists (GOCACHE=$GOCACHE)." "Compilando yay antes de procesar las listas (GOCACHE=$GOCACHE).")"
      if ! git clone --depth 1 https://aur.archlinux.org/yay.git /tmp/yay-build >/tmp/yay-clone.log 2>&1; then
        err "$(tail -n 20 /tmp/yay-clone.log 2>/dev/null || true)"
        die "$(T "Could not clone yay; stopping before package lists." "No se pudo clonar yay; se detiene antes de procesar las listas.")"
      fi
      if ! (cd /tmp/yay-build && makepkg -si --noconfirm) >/tmp/yay-build.log 2>&1; then
        err "$(tail -n 30 /tmp/yay-build.log 2>/dev/null || true)"
        rm -rf /tmp/yay-build
        die "$(T "Could not build yay; stopping before package lists." "No se pudo compilar yay; se detiene antes de procesar las listas.")"
      fi
      rm -rf /tmp/yay-build
      command -v yay >/dev/null 2>&1 || die "$(T "yay build completed but the executable is unavailable." "yay se compiló, pero el ejecutable no está disponible.")"
      AUR_HELPER="yay"
      ok "$(T "yay is ready; package lists can now be processed." "yay está listo; ahora se procesarán las listas de paquetes.")"
    fi
  fi
fi

# ══════════════════════════════════════════════════════ 4. Paquetes ═════
step "$(T "Packages" "Paquetes")"

resolve_conflict_and_install() {
  local p="$1" out other
  if out="$(as_root pacman -S --needed --noconfirm "$p" 2>&1)"; then
    return 0
  fi
  if ! printf '%s' "$out" | grep -qiE "are in conflict"; then
    warn "$(T "  ✗ could not install:" "  ✗ no se pudo instalar:") $p"
    err "    $(printf '%s' "$out" | grep -vE '^\s*$' | tail -1 || true)"
    return 1
  fi
  other="$(printf '%s' "$out" \
    | grep -oE '[a-zA-Z0-9@._+:-]+-[0-9][^ ]*-[0-9]+' \
    | head -2 | tail -1 | sed -E 's/-[0-9][^-]*-[0-9]+$//' || true)"
  if [[ -z "$other" || "$other" == "$p" ]]; then
    warn "$(T "  ✗ $p: conflict could not be resolved" "  ✗ $p: conflicto que no pude resolver")"
    return 1
  fi
  if [[ "$other" != "$p" ]] && ! pacman -Qq "$other" &>/dev/null; then
    other="$(printf '%s' "$out" | grep -oE '[a-zA-Z0-9@._+:-]+-[0-9][^ ]*-[0-9]+' \
      | head -1 | sed -E 's/-[0-9][^-]*-[0-9]+$//' || true)"
  fi
  info "$(T "    $p conflicts with $other, which is already installed" "    $p choca con $other, que ya está instalado")"
  if ask "$(T "    Remove $other?" "    ¿Quitar $other?")"; then
    [[ $DRY -eq 1 ]] && return 0
    as_root pacman -R --noconfirm "$other" >/dev/null 2>&1 || {
      warn "$(T "    Could not remove $other" "    No se pudo quitar $other")"; return 1; }
    if as_root pacman -S --needed --noconfirm "$p" >/dev/null 2>&1; then
      ok "    $other → $p"
      return 0
    fi
  fi
  warn "$(T "  ✗ could not install $p (unresolved conflict with $other)" "  ✗ no se pudo instalar $p (conflicto con $other sin resolver)")"
  return 1
}

inst() {
  [[ $NO_PKGS -eq 1 || $VERIFY_ONLY -eq 1 ]] && return 0
  local file="$1" via="${2:-pacman}" fail=0
  local -a all=() want=() missing=()
  mapfile -t all < <(pkgs "$file")
  [[ ${#all[@]} -eq 0 ]] && return 0

  local excl=(); mapfile -t excl < <(pkgs "$REPO/packages/no-instalar.txt")
  mapfile -t want < <(printf '%s\n' "${all[@]}" | grep -vxF -f <(printf '%s\n' "${excl[@]}") || true)
  if [[ ${#want[@]} -eq 0 ]]; then info "$(T "$(basename "$file"): nothing to install" "$(basename "$file"): nada que instalar")"; return 0; fi

  local -a chao=() went=()
  if [[ -f "$REPO/packages/chaotic.txt" ]]; then
    mapfile -t chao < <(pkgs "$REPO/packages/chaotic.txt")
  fi
  if [[ "$via" == "pacman" && "$CHAOTIC" -eq 0 && ${#chao[@]} -gt 0 ]]; then
    local p c
    for p in "${want[@]}"; do
      for c in "${chao[@]}"; do [[ "$p" == "$c" ]] && { went+=("$p"); break; }; done
    done
    if [[ ${#went[@]} -gt 0 ]]; then
      info "$(T "$(basename "$file"): ${#went[@]} will use the AUR because Chaotic-AUR is disabled" "$(basename "$file"): ${#went[@]} van por AUR porque Chaotic-AUR está desactivado")"
      if [[ $DRY -eq 1 ]]; then
        info "[dry-run] ${AUR_HELPER:-yay} -S ${went[*]}"
      elif [[ -n "$AUR_HELPER" ]]; then
        "$AUR_HELPER" -S --needed --noconfirm "${went[@]}" || warn "$(T "Some AUR packages failed" "Falló la instalación de algunos paquetes AUR")"
      else
        warn "$(T "No yay/paru helper is available to install:" "No hay un ayudante yay/paru para instalar:") ${went[*]}"
      fi
      mapfile -t want < <(printf '%s\n' "${want[@]}" | grep -vxF -f <(printf '%s\n' "${went[@]}") || true)
    fi
  fi

  if [[ "$via" == "pacman" ]]; then
    local p
    for p in "${want[@]}"; do
      pacman -Si "$p" &>/dev/null || missing+=("$p")
    done
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "$(T "$(basename "$file"): ${#missing[@]} not found in your repositories; skipping" "$(basename "$file"): ${#missing[@]} no existen en tus repos; se omiten")"
    local p; for p in "${missing[@]}"; do info "$(T "    not found:" "    no encontrado:") $p"; done
  fi
  if [[ ${#missing[@]} -eq ${#want[@]} ]]; then
    warn "$(T "$(basename "$file"): no installable packages remain" "$(basename "$file"): no quedó ningún paquete instalable")"; return 0
  fi
  local -a final=()
  local p hit m
  for p in "${want[@]}"; do
    hit=0
    for m in ${missing[@]+"${missing[@]}"}; do [[ "$p" == "$m" ]] && { hit=1; break; }; done
    [[ $hit -eq 0 ]] && final+=("$p")
  done

  if [[ "$via" == "pacman" ]]; then
    local -a drop=()
    local d c owner
    for p in "${final[@]}"; do
      for c in $(pacman -Si "$p" 2>/dev/null | awk -F': *' '/^Conflicts With/{print $2}'); do
        [[ -z "$c" || "$c" == "None" ]] && continue
        owner="$(pacman -Qqo "$c" 2>/dev/null | head -1 || true)"
        [[ -z "$owner" ]] && continue
        if printf '%s\n' "${final[@]}" | grep -qx "$owner"; then
          continue
        fi
        drop+=("$owner")
      done
    done
    if [[ ${#drop[@]} -gt 0 ]]; then
      local -a uniq=()
      local seen u
      for d in "${drop[@]}"; do
        seen=0
        for u in ${uniq[@]+"${uniq[@]}"}; do [[ "$d" == "$u" ]] && { seen=1; break; }; done
        [[ $seen -eq 0 ]] && uniq+=("$d")
      done
      info "$(T "Conflicts: the following will be replaced: ${uniq[*]}" "Conflictos: se reemplazarán los siguientes: ${uniq[*]}")"
      for d in "${uniq[@]}"; do info "$(T "    ${d} → replaced by a package from this setup" "    ${d} → lo reemplazará un paquete de esta configuración")"; done
      if ask "$(T "Remove ${uniq[*]}?" "¿Quitar ${uniq[*]}?")"; then
        [[ $DRY -eq 1 ]] && info "[dry-run] pacman -R --noconfirm ${uniq[*]}"
        [[ $DRY -eq 0 ]] && { as_root pacman -R --noconfirm "${uniq[@]}" 2>/dev/null \
          || warn "$(T "Could not remove conflicting packages; something may depend on them." "No se pudieron quitar los conflictos; puede que algún paquete los necesite.")"; }
      else
        warn "$(T "Conflicts were kept; conflicting packages will NOT be installed." "Se conservaron los conflictos; los paquetes incompatibles NO se instalarán.")"
        local -a blocked=()
        for p in "${final[@]}"; do
          for c in $(pacman -Si "$p" 2>/dev/null | awk -F': *' '/^Conflicts With/{print $2}'); do
            [[ -z "$c" || "$c" == "None" ]] && continue
            pacman -Qq "$c" &>/dev/null && blocked+=("$p")
          done
        done
        mapfile -t final < <(printf '%s\n' "${final[@]}" | grep -vxF -f <(printf '%s\n' "${blocked[@]}" | sort -u) || true)
      fi
    fi
  fi

  info "$(T "$(basename "$file"): ${#final[@]} packages" "$(basename "$file"): ${#final[@]} paquetes")"
  [[ $DRY -eq 1 ]] && { info "$(T "[dry-run] would install:" "[dry-run] se instalarían:") ${final[*]}"; return 0; }

  local chunk=15 i n=0
  local aur=0
  [[ "$via" == "yay" || "$via" == "paru" ]] && aur=1
  for ((i=0; i<${#final[@]}; i+=chunk)); do
    local -a slice=("${final[@]:i:chunk}")
    if [[ $aur -eq 1 ]]; then
      mkdir -p "$AUR_LOG" 2>/dev/null || true
      local -a prebuilt=() needbuild=()
      for p in "${slice[@]}"; do
        if pacman -Si "$p" &>/dev/null; then prebuilt+=("$p"); else needbuild+=("$p"); fi
      done
      if [[ ${#prebuilt[@]} -gt 0 ]]; then
        info "$(T "$(basename "$file"): ${#prebuilt[@]} available from repositories (no build needed)" "$(basename "$file"): ${#prebuilt[@]} disponibles en repositorios (sin compilar)")"
        as_root pacman -S --needed --noconfirm "${prebuilt[@]}" >/dev/null 2>&1 || true
        for p in "${prebuilt[@]}"; do
          if pacman -Qq "$p" &>/dev/null; then n=$((n+1))
          else fail=$((fail+1)); warn "$(T "  x was not installed:" "  x no quedó instalado:") $p"; fi
        done
      fi
      [[ ${#needbuild[@]} -eq 0 ]] && continue
      slice=("${needbuild[@]}")
      info "$(T "$(basename "$file"): ${#needbuild[@]} packages need to be built" "$(basename "$file"): hay que compilar ${#needbuild[@]} paquetes")"
      "$via" -S --needed --noconfirm "${slice[@]}" >/tmp/rice-aur-lote.log 2>&1 || true
      local p other
      for p in "${slice[@]}"; do
        pacman -Qq "$p" &>/dev/null && { n=$((n+1)); continue; }
        if ! "$via" -S --needed --noconfirm "$p" >"$AUR_LOG/$p.log" 2>&1; then
          cp /tmp/rice-aur-lote.log "$AUR_LOG/$p.log" 2>/dev/null || true
        fi
        if pacman -Qq "$p" &>/dev/null; then
          n=$((n+1)); rm -f "$AUR_LOG/$p.log" 2>/dev/null || true; continue
        fi
        if grep -qiE "are in conflict" "$AUR_LOG/$p.log" 2>/dev/null; then
          other="$(grep -oE '[a-zA-Z0-9@._+:-]+-[0-9][^ ]*-[0-9]+' "$AUR_LOG/$p.log" 2>/dev/null \
                   | head -2 | tail -1 | sed -E 's/-[0-9][^-]*-[0-9]+$//' || true)"
          if [[ -n "$other" && "$other" != "$p" ]] && pacman -Qq "$other" &>/dev/null; then
            info "$(T "    $p conflicts with $other, which is already installed" "    $p choca con $other, que ya está instalado")"
            if ask "$(T "    Remove $other?" "    ¿Quitar $other?")"; then
              as_root pacman -R --noconfirm "$other" >/dev/null 2>&1 || true
              "$via" -S --needed --noconfirm "$p" >/dev/null 2>&1 || true
              if pacman -Qq "$p" &>/dev/null; then
                ok "    $other → $p"; n=$((n+1)); rm -f "$AUR_LOG/$p.log" 2>/dev/null || true; continue
              fi
            fi
          fi
        fi
        fail=$((fail+1))
        warn "$(T "  x could not install:" "  x no se pudo instalar:") $p"
        err "    $(grep -vE '^\s*$' "$AUR_LOG/$p.log" 2>/dev/null | tail -1 || true)"
        info "    Log: $AUR_LOG/$p.log"
      done
      continue
    fi

    local out=""
    if out="$(as_root pacman -S --needed --noconfirm "${slice[@]}" 2>&1)"; then
      n=$((n+${#slice[@]}))
    else
      printf '%s\n' "$out" | grep -qiE "are in conflict" \
        && warn "$(T "Conflicts in this batch; retrying packages one by one." "Hay conflictos en el lote; se reintentará paquete por paquete.")"
      local p
      for p in "${slice[@]}"; do
        if resolve_conflict_and_install "$p"; then
          n=$((n+1))
        else
          fail=$((fail+1))
        fi
      done
    fi
  done
  ok "$(T "Installed $n of ${#final[@]} packages" "Instalados $n de ${#final[@]} paquetes")"
  if [[ $fail -gt 0 ]]; then warn "$(T "$fail packages failed; details are shown above." "Fallaron $fail paquetes; el detalle aparece arriba.")"; fi
  return 0
}

if [[ $VERIFY_ONLY -eq 0 ]]; then
  inst "$REPO/packages/base.txt"
  [[ $NO_GPU   -eq 0 && -f "$REPO/packages/gpu-$GPU_KIND.txt" ]] && inst "$REPO/packages/gpu-$GPU_KIND.txt"
  [[ $NO_FONTS -eq 0 ]] && inst "$REPO/packages/fuentes.txt"
  [[ $NO_APPS  -eq 0 ]] && inst "$REPO/packages/extras.txt"

  if [[ $NO_PKGS -eq 0 && $NO_AUR -eq 0 && -s "$REPO/packages/aur.txt" ]]; then
    if [[ -n "$AUR_HELPER" ]]; then
      inst "$REPO/packages/aur.txt" "$AUR_HELPER"
    elif [[ $DRY -eq 1 ]]; then
      info "$(T "AUR helper bootstrap is shown before package lists above." "La preparación del ayudante AUR aparece antes de las listas de paquetes.")"
      for p in $(pkgs "$REPO/packages/aur.txt"); do info "    yay -S $p"; done
    else
      die "$(T "AUR packages were requested but no helper was prepared before package installation." "Se solicitaron paquetes AUR, pero no se preparó un ayudante antes de instalar paquetes.")"
    fi
  fi

  if [[ $NO_PKGS -eq 0 && -n "$(pkgs "$REPO/packages/flatpak.txt")" ]] && command -v flatpak >/dev/null 2>&1; then
    while read -r app; do
      [[ -z "$app" ]] && continue
      flatpak info "$app" >/dev/null 2>&1 || run flatpak install -y --noninteractive flathub "$app" \
        || warn "$(T "Could not install" "No se pudo instalar") $app"
    done < <(pkgs "$REPO/packages/flatpak.txt")
  fi
else
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
fi

# ══════════════════════════════════════════════════════ 5. oh-my-zsh ═════
step "$(T "Shell dependencies" "Dependencias de shell")"
if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
elif [[ ! -d "$NEW_HOME/.oh-my-zsh" ]]; then
  if [[ $DRY -eq 1 ]]; then info "$(T "[dry-run] would clone oh-my-zsh" "[dry-run] se clonaría oh-my-zsh")"
  else git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$NEW_HOME/.oh-my-zsh" \
    && ok "$(T "oh-my-zsh cloned" "oh-my-zsh clonado")" || warn "$(T "Could not clone oh-my-zsh" "No se pudo clonar oh-my-zsh")"
  fi
else
  ok "$(T "oh-my-zsh is already installed" "oh-my-zsh ya está instalado")"
fi

# ══════════════════════════════════════════════════════ 6. $HOME ═════════
step "$(T "Your \$HOME" "Tu \$HOME")"
n=0; fail=0; skipped=0
if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
else
  mkdir -p "$NEW_HOME" 2>/dev/null || true
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO/home/"}"
    if skip_home "$rel"; then
      skipped=$((skipped+1))
      continue
    fi
    dst="$NEW_HOME/$rel"
    if [[ -e "$dst" && ! -L "$dst" ]] || [[ -L "$dst" && -e "$dst" ]]; then
      if ! cmp -s "$src" "$dst" 2>/dev/null; then
        if [[ $DRY -eq 0 ]]; then
          mkdir -p "$STASH/$(dirname "$rel")" 2>/dev/null || true
          cp -a "$dst" "$STASH/$rel" 2>/dev/null || true
        fi
      fi
    fi
    if [[ $DRY -eq 1 ]]; then n=$((n+1)); continue; fi
    if ! mkdir -p "$(dirname "$dst")" 2>/dev/null; then
      warn "$(T "Could not create $(dirname "$rel"); skipping" "No se pudo crear $(dirname "$rel"); se omite")"; fail=$((fail+1)); continue
    fi
    if ! cp -a "$src" "$dst" 2>/dev/null; then
      rm -f "$dst" 2>/dev/null || true
      if ! cp -a "$src" "$dst" 2>/dev/null; then
        warn "$(T "Could not copy $rel (permissions); leaving it unchanged" "No se pudo copiar $rel (permisos); se deja sin cambios")"
        fail=$((fail+1))
        continue
      fi
    fi
    if [[ -f "$dst" && "$ORIGIN_HOME" != "$NEW_HOME" ]] && grep -Iq . "$dst" 2>/dev/null; then
      grep -qF "$ORIGIN_HOME" "$dst" 2>/dev/null && \
        sed -i "s|$ORIGIN_HOME|$NEW_HOME|g" "$dst" 2>/dev/null || true
    fi
    n=$((n+1))
  done < <(find "$REPO/home" -mindepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
  ok "$(T "$n files → $NEW_HOME" "$n archivos → $NEW_HOME")"
  [[ $skipped -gt 0 ]] && info "$(T "Skipped $skipped personal state/cache files (--copy-all includes them)" "Se omitieron $skipped archivos de estado personal/caché (--copy-all los incluye)")"
  [[ $fail -gt 0 ]] && warn "$(T "$fail files could not be copied (permissions)" "$fail archivos no se pudieron copiar (permisos)")"
  [[ -d "$STASH" ]] && info "$(T "Previous files were backed up to" "Los archivos anteriores se respaldaron en") $STASH"
fi

apply_optional_profile() {
  if [[ -n "$PROFILE_DIR" ]]; then
    local profile_dir="$PROFILE_DIR"
    if [[ ! -d "$profile_dir" ]]; then
      die "$(T "External profile not found:" "No se encontró el perfil externo:") $profile_dir"
    fi
    if [[ -n "$PROFILE_NAME" && "$PROFILE_NAME" != "custom" ]]; then
      warn "$(T "--profile-dir takes precedence over --profile=$PROFILE_NAME" "--profile-dir tiene prioridad sobre --profile=$PROFILE_NAME")"
    fi
    PROFILE_NAME="custom"
  elif [[ -z "$PROFILE_NAME" || "$PROFILE_NAME" == "none" ]]; then
    return 0
  else
    local profile_dir="$REPO/profiles/$PROFILE_NAME"
    if [[ "$PROFILE_NAME" == "custom" ]]; then
      die "$(T "--profile=custom requires --profile-dir=PATH" "--profile=custom requiere --profile-dir=RUTA")"
    fi
    if [[ ! -d "$profile_dir" ]]; then
      die "$(T "Profile not found: $PROFILE_NAME (looked in $profile_dir)" "No se encontró el perfil: $PROFILE_NAME (se buscó en $profile_dir)")"
    fi
  fi

  local profile_dir="${PROFILE_DIR:-$REPO/profiles/$PROFILE_NAME}"
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would apply optional profile: ${PROFILE_NAME:-custom} → $NEW_HOME" "[dry-run] se aplicaría el perfil opcional: ${PROFILE_NAME:-custom} → $NEW_HOME")"
    return 0
  fi
  warn "$(T "Applying optional profile:" "Aplicando el perfil opcional:") ${PROFILE_NAME:-custom}"
  if [[ -e "$NEW_HOME/.local" ]]; then
    mkdir -p "$STASH/profile-backups" 2>/dev/null || true
    cp -a "$NEW_HOME/.local" "$STASH/profile-backups/.local.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
  fi
  cp -a "$profile_dir/." "$NEW_HOME/" 2>/dev/null || {
    warn "$(T "Could not apply profile ${PROFILE_NAME:-custom} to" "No se pudo aplicar el perfil ${PROFILE_NAME:-custom} en") $NEW_HOME"
    return 1
  }
  local profile_source profile_rel profile_target profile_home profile_home_sed
  profile_home="$NEW_HOME"
  profile_home="${profile_home//\\/\\\\}"
  profile_home="${profile_home//&/\\&}"
  profile_home="${profile_home//|/\\|}"
  printf -v profile_home_sed 's|\\${HOME}|%s|g; s|\\$HOME|%s|g' "$profile_home" "$profile_home"
  while IFS= read -r -d '' profile_source; do
    profile_rel="${profile_source#"$profile_dir"/}"
    profile_target="$NEW_HOME/$profile_rel"
    if [[ -f "$profile_target" ]] && grep -Iq . "$profile_target" 2>/dev/null \
       && { grep -qF '$HOME' "$profile_target" || grep -qF '${HOME}' "$profile_target"; }; then
      sed -i "$profile_home_sed" "$profile_target"
    fi
  done < <(find "$profile_dir" -type f -print0 2>/dev/null)
  ok "$(T "Profile ${PROFILE_NAME:-custom} applied to" "Perfil ${PROFILE_NAME:-custom} aplicado en") $NEW_HOME"
}

if [[ $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  apply_optional_profile
fi

if [[ $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  [[ ! -e "$NEW_HOME/.gtkrc-2.0.mine" ]] && { : > "$NEW_HOME/.gtkrc-2.0.mine"; ok "$(T "Created .gtkrc-2.0.mine" "Se creó .gtkrc-2.0.mine")"; }
fi

# ══════════════════════════════════════════════════════ 7. assets ════════
step "$(T "Resources" "Recursos")"
if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
else
  if [[ -d "$REPO/assets/fastfetch/logos" ]]; then
    if [[ $DRY -eq 0 ]]; then
      mkdir -p "$NEW_HOME/.config/fastfetch" 2>/dev/null || true
      cp -a "$REPO/assets/fastfetch/logos" "$NEW_HOME/.config/fastfetch/logos" 2>/dev/null || warn "$(T "Could not copy fastfetch logos" "No se pudieron copiar los logos de fastfetch")"
      [[ -f "$REPO/assets/fastfetch/random-logo.sh" ]] && \
        cp -a "$REPO/assets/fastfetch/random-logo.sh" "$NEW_HOME/.config/fastfetch/" 2>/dev/null || true
      chmod +x "$NEW_HOME/.config/fastfetch/random-logo.sh" 2>/dev/null || true
      ok "$(T "fastfetch logos ($(find "$NEW_HOME/.config/fastfetch/logos" -type f 2>/dev/null | wc -l) images)" "Logos de fastfetch ($(find "$NEW_HOME/.config/fastfetch/logos" -type f 2>/dev/null | wc -l) imágenes)")"
    else
      info "$(T "[dry-run] would copy $(find "$REPO/assets/fastfetch/logos" -type f 2>/dev/null | wc -l) logos" "[dry-run] se copiarían $(find "$REPO/assets/fastfetch/logos" -type f 2>/dev/null | wc -l) logos")"
    fi
  fi
  if [[ -f "$REPO/assets/omp/paradox.omp.json" && $DRY -eq 0 ]]; then
    mkdir -p "$NEW_HOME/.cache/oh-my-posh/themes" 2>/dev/null || true
    cp -a "$REPO/assets/omp/paradox.omp.json" "$NEW_HOME/.cache/oh-my-posh/themes/" 2>/dev/null || warn "$(T "Could not copy the oh-my-posh theme" "No se pudo copiar el tema de oh-my-posh")"
    ok "$(T "oh-my-posh theme" "Tema de oh-my-posh")"
  fi
  if [[ -n "$IMAGES" ]]; then
    if [[ -d "$IMAGES" ]]; then
      run mkdir -p "$NEW_HOME/.config/fastfetch/PNG"
      [[ $DRY -eq 0 ]] && cp -a "$IMAGES/." "$NEW_HOME/.config/fastfetch/PNG/"
      ok "$(T "fastfetch PNGs copied from" "PNGs de fastfetch copiados desde") $IMAGES"
    else
      warn "$(T "Image directory does not exist:" "No existe el directorio de imágenes:") $IMAGES"
    fi
  fi
  install_krystalsvg
fi

# ══════════════════════════════════════════════════════ 8. /etc ══════════
step "$(T "System configuration (/etc)" "Configuración del sistema (/etc)")"
if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
elif [[ $USER_ONLY -eq 1 ]]; then
  warn "$(T "Skipped (--user-only)" "Omitido (--user-only)")"
else
  m=0; mfail=0
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO/etc/"}"
    dst="/$rel"
    if [[ -e "$dst" ]]; then
      if ! cmp -s "$src" "$dst" 2>/dev/null; then
        if [[ $DRY -eq 0 ]]; then
          as_root mkdir -p "$STASH/etc/$(dirname "$rel")"
          as_root cp -a "$dst" "$STASH/etc/$rel" 2>/dev/null || true
        fi
      fi
    fi
    [[ $DRY -eq 1 ]] && { m=$((m+1)); continue; }
    if ! as_root mkdir -p "$(dirname "$dst")" 2>/dev/null \
       || ! as_root cp -a "$src" "$dst" 2>/dev/null; then
      as_root rm -f "$dst" 2>/dev/null || true
      as_root cp -a "$src" "$dst" 2>/dev/null || { warn "$(T "Could not copy /$rel" "No se pudo copiar /$rel")"; mfail=$((mfail+1)); continue; }
    fi
    m=$((m+1))
  done < <(find "$REPO/etc" -mindepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
  ok "$(T "$m files → /etc" "$m archivos → /etc")"
  [[ ${mfail:-0} -gt 0 ]] && warn "$(T "$mfail /etc files could not be copied" "$mfail archivos de /etc no se pudieron copiar")"
  as_root systemctl daemon-reload 2>/dev/null || true
fi

if [[ -d "$REPO/machine" && $UNINSTALL -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO/machine/"}"
    case "$rel" in
      *.plantilla) continue ;;
      etc/*)   [[ $USER_ONLY -eq 1 ]] && continue
               dst="/$rel" ;;
      home/*)  dst="$NEW_HOME/${rel#home/}" ;;
      *) continue ;;
    esac
    if [[ -e "$dst" ]]; then
      ok "$(T "${dst} already exists; leaving it unchanged" "${dst} ya existe; se deja sin cambios")"
    elif [[ $DRY -eq 1 ]]; then
      info "$(T "[dry-run] would create $dst (does not exist yet)" "[dry-run] se crearía $dst (todavía no existe)")"
    else
      as_root mkdir -p "$(dirname "$dst")"
      as_root cp -a "$src" "$dst"
      warn "$(T "Created $dst; review it because it is machine-specific" "Se creó $dst; revísalo porque es específico de esta máquina")"
    fi
  done < <(find "$REPO/machine" -mindepth 2 -type f -print0 2>/dev/null)
fi

# ══════════════════════════════════════════════════════ 9. Display manager
step "$(T "Login and session" "Inicio de sesión")"


sddm_audio_group() {
  local apply=0
  [[ "${1:-}" == "--apply" ]] && apply=1
  if ! getent passwd sddm >/dev/null 2>&1; then
    warn "$(T "The sddm user does not exist; the login screen cannot start" "El usuario sddm no existe; la pantalla de inicio no puede arrancar")"
    return 1
  fi
  if ! getent group audio >/dev/null 2>&1; then
    warn "$(T "The 'audio' group does not exist; the login startup sound will not play" "No existe el grupo 'audio'; el sonido de inicio no sonará")"
    return 1
  fi
  if ! id -nG sddm 2>/dev/null | tr ' ' '\n' | grep -qx audio; then
    if [[ $apply -eq 0 ]]; then
      warn "$(T "The sddm user is not in the 'audio' group; the login startup sound will not play: sudo usermod -aG audio sddm" "El usuario sddm no está en el grupo 'audio'; el sonido de inicio no sonará: sudo usermod -aG audio sddm")"
      return 1
    fi
    if [[ $DRY -eq 1 ]]; then
      info "$(T "[dry-run] would add the sddm user to the audio group" "[dry-run] se añadiría el usuario sddm al grupo audio")"
      return 0
    fi
    if ! as_root usermod -aG audio sddm 2>/dev/null; then
      warn "$(T "Could not add sddm to the audio group; the login startup sound will not play" "No se pudo añadir sddm al grupo audio; el sonido de inicio no sonará")"
      return 1
    fi
    if ! id -nG sddm 2>/dev/null | tr ' ' '\n' | grep -qx audio; then
      warn "$(T "sddm was added to 'audio' but it is not reflected yet; the login startup sound will not play" "sddm se añadió a 'audio' pero aún no se refleja; el sonido de inicio no sonará")"
      return 1
    fi
    ok "$(T "sddm added to the audio group (login screen can play the startup sound)" "sddm añadido al grupo audio (la pantalla de inicio puede reproducir el sonido)")"
    info "$(T "Reboot or log out so the greeter starts with the new group" "Reiniciá o cerrá sesión para que el greeter arranque con el grupo nuevo")"
    return 0
  fi
  ok "$(T "Greeter audio access: sddm ∈ audio" "Acceso de audio del greeter: sddm ∈ audio")"
  return 0
}


sddm_audio_early_start() {
  local apply=0
  [[ "${1:-}" == "--apply" ]] && apply=1
  local target=/usr/lib/systemd/user/pipewire.service
  local dir=/var/lib/sddm/.config/systemd/user/default.target.wants
  local link=$dir/pipewire.service

  if ! getent passwd sddm >/dev/null 2>&1; then
    warn "$(T "The sddm user does not exist; the login screen cannot start" "El usuario sddm no existe; la pantalla de inicio no puede arrancar")"
    return 1
  fi
  if [[ ! -f $target ]]; then
    warn "$(T "pipewire.service was not found; the greeter audio stack will start late" "No se encontró pipewire.service; el stack de audio del greeter arrancará tarde")"
    return 1
  fi

  local verdict=""   # ok | bad | missing | unknown
  if [[ -r $dir ]]; then
    if [[ -L $link && "$(readlink "$link" 2>/dev/null)" == "$target" ]]; then
      verdict=ok
    elif [[ -e $link || -L $link ]]; then verdict=bad
    else verdict=missing
    fi
  elif [[ $DRY -eq 1 ]]; then
    verdict=unknown
  else
    verdict="$(as_root sh -c 'if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then echo ok; elif [ -e "$1" ] || [ -L "$1" ]; then echo bad; else echo missing; fi' _ "$link" "$target" 2>/dev/null || true)"
    [[ -n $verdict ]] || verdict=unknown
  fi

  if [[ $verdict == ok ]]; then
    ok "$(T "Greeter audio stack starts with its session" "El stack de audio del greeter arranca con su sesión")"
    return 0
  fi
  if [[ $verdict == unknown && $apply -eq 0 ]]; then
    info "$(T "Greeter audio start: not checked (reading $link requires root). Check with: sudo ./install.sh --verify" "Arranque de audio del greeter: sin comprobar (leer $link exige root). Comprobá con: sudo ./install.sh --verify")"
    return 0
  fi
  if [[ $apply -eq 0 ]]; then
    warn "$(T "The greeter audio stack starts only when Qt connects (~0.5 s later); run: sudo mkdir -p $dir && sudo ln -sfn $target $link" "El stack de audio del greeter sólo arranca cuando conecta Qt (~0,5 s después); ejecutá: sudo mkdir -p $dir && sudo ln -sfn $target $link")"
    return 1
  fi
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would start the greeter audio stack with its session ($link)" "[dry-run] se arrancaría el stack de audio del greeter con su sesión ($link)")"
    return 0
  fi
  if ! as_root mkdir -p "$dir" || ! as_root ln -sfn "$target" "$link"; then
    warn "$(T "Could not start the greeter audio stack with its session; the startup sound will be ~0.5 s late" "No se pudo arrancar el stack de audio del greeter con su sesión; el sonido de inicio llegará ~0,5 s tarde")"
    return 1
  fi
  ok "$(T "Greeter audio stack starts with its session (earlier startup sound)" "El stack de audio del greeter arranca con su sesión (sonido de inicio antes)")"
  return 0
}

dm_sddm() {
  if [[ -d "$REPO/assets/sddm" ]]; then
    local t name
    for t in "$REPO/assets/sddm"/*/; do
      [[ -d "$t" ]] || continue
      name="$(basename "$t")"
      if [[ $DRY -eq 0 ]]; then
        as_root mkdir -p /usr/share/sddm/themes
        as_root cp -a "$t" /usr/share/sddm/themes/
        ok "$(T "Theme $name → /usr/share/sddm/themes/" "Tema $name → /usr/share/sddm/themes/")"
      else
        info "$(T "[dry-run] would copy $name to /usr/share/sddm/themes/" "[dry-run] se copiaría $name a /usr/share/sddm/themes/")"
      fi
    done
  fi
  local theme; theme="$(basename "$(find "$REPO/assets/sddm" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)")"
  [[ -z "$theme" ]] && theme="sddm-2.0-theme"
  local cfg="[Theme]
Current=$theme"
  if [[ $DRY -eq 0 ]]; then
    as_root cp -a /etc/sddm.conf "$STASH/sddm.conf.bak" 2>/dev/null || true
    if printf '%s\n' "$cfg" | as_root tee /etc/sddm.conf >/dev/null 2>&1; then
      if as_root grep -q "^Current=$theme$" /etc/sddm.conf 2>/dev/null; then
        ok "$(T "/etc/sddm.conf → theme $theme (verified)" "/etc/sddm.conf → tema $theme (verificado)")"
      else
        warn "$(T "/etc/sddm.conf was written but does not contain Current=$theme" "/etc/sddm.conf se escribió pero no contiene Current=$theme")"
      fi
    else
      warn "$(T "Could not write /etc/sddm.conf; the login screen may have no theme" "No se pudo escribir /etc/sddm.conf; la pantalla de inicio podría quedar sin tema")"
    fi
  else
    info "$(T "[dry-run] would write /etc/sddm.conf with Current=$theme" "[dry-run] se escribiría /etc/sddm.conf con Current=$theme")"
  fi

  sddm_audio_group --apply || true
  sddm_audio_early_start --apply || true
  if ! ls /usr/share/wayland-sessions/*hyprland* >/dev/null 2>&1; then
    warn "$(T "Hyprland was not found in /usr/share/wayland-sessions; it may not appear on the login screen" "No se encontró Hyprland en /usr/share/wayland-sessions; podría no aparecer en el inicio de sesión")"
  fi
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would enable sddm and set graphical.target as default" "[dry-run] se habilitaría sddm y se establecería graphical.target como predeterminado")"
  else
    if as_root systemctl enable sddm 2>/dev/null; then
      ok "$(T "sddm enabled" "sddm habilitado")"
    else
      warn "$(T "Could not enable sddm; the login screen will not appear" "No se pudo habilitar sddm; no aparecerá la pantalla de inicio")"
    fi
    if as_root systemctl set-default graphical.target 2>/dev/null; then
      ok "$(T "Boot target:" "Objetivo de arranque:") $(systemctl get-default 2>/dev/null || echo '?')"
    else
      warn "$(T "Could not set graphical.target as default" "No se pudo establecer graphical.target como predeterminado")"
      info "    sudo systemctl enable sddm && sudo systemctl set-default graphical.target"
    fi
  fi
  if systemctl list-unit-files 2>/dev/null | grep -q "^greetd.service"; then
    as_root systemctl disable --now greetd 2>/dev/null || true
    ok "$(T "greetd disabled (using sddm)" "greetd deshabilitado (se usa sddm)")"
  fi
}

dm_greetd() {
  local greeter_bin="/usr/bin/noctalia-greeter-session"
  local cmd="agreety --cmd /bin/sh"
  local user="greeter"
  if [[ -x "$greeter_bin" ]]; then
    cmd="$greeter_bin"; user="greeter"
  fi
  if [[ $DRY -eq 0 ]]; then
    as_root useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2>/dev/null || true
    [[ -x /usr/share/noctalia-greeter/setup_greetd_pam.sh ]] && \
      { as_root /usr/share/noctalia-greeter/setup_greetd_pam.sh; ok "$(T "greetd PAM configured" "PAM de greetd configurado")"; }
    as_root mkdir -p /etc/greetd
    as_root tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$cmd"
user = "$user"
EOF
    ok "$(T "/etc/greetd/config.toml written" "/etc/greetd/config.toml escrito")"
  else
    info "$(T "[dry-run] would create the greeter user and write config.toml with $cmd" "[dry-run] se crearía el usuario greeter y se escribiría config.toml con $cmd")"
  fi
  as_root systemctl enable greetd 2>/dev/null || warn "$(T "Could not enable greetd" "No se pudo habilitar greetd")"
  as_root systemctl set-default graphical.target 2>/dev/null \
    || warn "$(T "Could not set graphical.target as default (greetd)" "No se pudo establecer graphical.target como predeterminado (greetd)")"
  if systemctl list-unit-files 2>/dev/null | grep -q "^sddm.service"; then
    as_root systemctl disable --now sddm 2>/dev/null || true
    ok "$(T "sddm disabled (using greetd)" "sddm deshabilitado (se usa greetd)")"
  fi
  ok "$(T "greetd enabled" "greetd habilitado")"
}

if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
else
  case "$DM" in
    sddm)   [[ $USER_ONLY -eq 1 ]] && warn "$(T "Skipped (--user-only)" "Omitido (--user-only)")" || dm_sddm ;;
    greetd) [[ $USER_ONLY -eq 1 ]] && warn "$(T "Skipped (--user-only)" "Omitido (--user-only)")" || dm_greetd ;;
    none)   warn "$(T "Display manager: no changes made" "Gestor de inicio: no se realizaron cambios")" ;;
  esac
fi

# ══════════════════════════════════════════════════════ 10. Dolphin+iconos

step "$(T "Dolphin and icons" "Dolphin e iconos")"

fix_icon_index() {
  local theme="$1"
  local src="/usr/share/icons/$theme/index.theme"
  local dst="$NEW_HOME/.local/share/icons/$theme/index.theme"
  local n
  n="$(grep -cE '^Type=(fixed|Fixed|threshold|Threshold)' "$src" 2>/dev/null || true)"
  n="${n:-0}"
  if [[ "$n" -gt 0 ]]; then
    if [[ -f "$dst" ]] && head -1 "$dst" 2>/dev/null | grep -q '^# rice:'; then
      rm -f "$dst" 2>/dev/null || true
    fi
    return 0
  fi
  n="$(grep -c '^Type=scalable' "$src" 2>/dev/null || true)"
  n="${n:-0}"
  [[ "$n" -eq 0 ]] && return 0
  mkdir -p "$(dirname "$dst")" 2>/dev/null || return 1
  { echo "# rice: index.theme patched by install.sh (Type=Scalable capitalization)"
    echo "# package uses lowercase and Qt6 does not recognize it; it falls back to hicolor"
    sed -e 's/^Type=scalable/Type=Scalable/' "$src" \
      | sed -E 's/^(Type=Scalable)$/Type=Scalable\nMinSize=25\nMaxSize=256/'
  } > "$dst" 2>/dev/null || return 1
  if grep -q '^Type=scalable' "$dst" 2>/dev/null; then
    rm -f "$dst" 2>/dev/null || true
    return 1
  fi
  local d rel sub
  d="$(dirname "$dst")"
  rel="$(sed -n 's/^Directories=//p' "$src" | tr ',' '\n' \
         | sed 's#/.*##' | sed '/^[[:space:]]*$/d' | sort -u || true)"
  for sub in $rel; do
    if [[ -d "/usr/share/icons/$theme/$sub" && ! -e "$d/$sub" ]]; then
      ln -sfn "/usr/share/icons/$theme/$sub" "$d/$sub" 2>/dev/null || true
    fi
  done
  return 0
}

rice_write_dolphin() {
  # Fuente de verdad: se escribe SIEMPRE, no se confía en home/ del repo.
  local wrap="$NEW_HOME/.local/bin/dolphin"
  local desk="$NEW_HOME/.local/share/applications/org.kde.dolphin.desktop"
  local dropdir="$NEW_HOME/.config/systemd/user/plasma-dolphin.service.d"
  local envd="$NEW_HOME/.config/environment.d/50-rice.conf"
  local hypr="$NEW_HOME/.config/hypr/hyprland.lua"

  mkdir -p "$(dirname "$wrap")" "$dropdir" \
           "$(dirname "$desk")" "$(dirname "$envd")" 2>/dev/null || return 1

  cat > "$wrap" <<'WRAP'
#!/bin/sh
# Wrapper de Dolphin: Kvantum + qt6ct SOLO para este proceso.
export QT_STYLE_OVERRIDE=kvantum
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
exec /usr/bin/dolphin "$@"
WRAP
  chmod +x "$wrap" 2>/dev/null || true
  ok "$(T "Wrapper → $wrap" "Wrapper → $wrap")"

  cat > "$desk" <<'DESK'
[Desktop Entry]
Type=Application
Name=Dolphin
GenericName=File Manager
Comment=Manage your files
Exec=/usr/bin/env QT_STYLE_OVERRIDE=kvantum QT_QPA_PLATFORMTHEME=qt6ct /usr/bin/dolphin %u
TryExec=/usr/bin/dolphin
Icon=org.kde.dolphin
Terminal=false
Categories=Qt;KDE;System;FileTools;FileManager;
MimeType=inode/directory;
StartupWMClass=dolphin
X-DBUS-ServiceName=org.kde.dolphin
X-KDE-Shortcuts=Meta+E
DESK
  ok "$(T ".desktop overlay (menu / krunner / gio)" ".desktop overlay (menú / krunner / gio)")"

  cat > "$dropdir/kvantum.conf" <<'DROP'
[Service]
Environment=QT_STYLE_OVERRIDE=kvantum
Environment=QT_QPA_PLATFORMTHEME=qt6ct
Environment=QT_QPA_PLATFORM=wayland;xcb
DROP
  ok "$(T "systemd drop-in (D-Bus / browser path)" "Drop-in de systemd (ruta D-Bus / navegador)")"

  cat > "$envd" <<'ENVD'
QT_QPA_PLATFORMTHEME=qt6ct
QT_QPA_PLATFORM=wayland;xcb
PATH=$HOME/.local/bin:$PATH
ENVD
  ok "$(T "environment.d/50-rice.conf (full session, including systemd --user)" "environment.d/50-rice.conf (sesión completa, incluido systemd --user)")"

  if [[ -f "$hypr" ]]; then
    if grep -qE 'fileManager = "/home/[^"]+/.local/bin/dolphin"' "$hypr"; then
      sed -i 's|local fileManager = "/home/[^"]*/\.local/bin/dolphin"|local fileManager = (os.getenv("HOME") or "") .. "/.local/bin/dolphin"|' "$hypr" 2>/dev/null \
        && ok "$(T "hyprland.lua: fileManager no longer uses another HOME" "hyprland.lua: fileManager ya no apunta a otro HOME")" \
        || warn "$(T "Could not rewrite fileManager in hyprland.lua; update it manually (docs/DOLPHIN.md)" "No se pudo reescribir fileManager en hyprland.lua; cámbialo manualmente (docs/DOLPHIN.md)")"
    fi
  fi
  systemctl --user daemon-reload 2>/dev/null || true
}

set_gtk_icon_theme() {
  local theme="$1" target_user target_uid target_bus dbus_address
  if ! command -v gsettings >/dev/null 2>&1; then
    warn "$(T "gsettings is unavailable; GTK settings.ini still selects $theme." "No está disponible gsettings; settings.ini de GTK mantiene $theme seleccionado.")"
    return 0
  fi

  if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
    target_user="$SUDO_USER"
    target_uid="$(id -u "$target_user")"
    target_bus="/run/user/$target_uid/bus"
    if [[ -S "$target_bus" ]] && sudo -u "$target_user" env \
      HOME="$NEW_HOME" XDG_CONFIG_HOME="$NEW_HOME/.config" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=$target_bus" \
      gsettings set org.gnome.desktop.interface icon-theme "$theme" 2>/dev/null; then
      ok "$(T "GTK icon theme set to $theme" "Tema de iconos GTK establecido en $theme")"
    else
      warn "$(T "Could not update GTK GSettings; GTK settings.ini still selects $theme." "No se pudo actualizar GSettings de GTK; settings.ini aún selecciona $theme.")"
    fi
  elif [[ $EUID -ne 0 && "$NEW_HOME" == "$HOME" ]]; then
    target_uid="$(id -u)"
    target_bus="/run/user/$target_uid/bus"
    dbus_address="${DBUS_SESSION_BUS_ADDRESS:-}"
    [[ -n "$dbus_address" || ! -S "$target_bus" ]] || dbus_address="unix:path=$target_bus"
    if [[ -n "$dbus_address" ]] && DBUS_SESSION_BUS_ADDRESS="$dbus_address" \
      gsettings set org.gnome.desktop.interface icon-theme "$theme" 2>/dev/null; then
      ok "$(T "GTK icon theme set to $theme" "Tema de iconos GTK establecido en $theme")"
    else
      warn "$(T "No user D-Bus session; GTK settings.ini selects $theme, but GSettings was not updated." "No hay sesión D-Bus del usuario; settings.ini selecciona $theme, pero GSettings no se actualizó.")"
    fi
  else
    info "$(T "GTK settings.ini selects $theme; GSettings was not changed for the alternate HOME." "settings.ini de GTK selecciona $theme; no se cambió GSettings para el HOME alternativo.")"
  fi
}

rice_fix_icons() {
  local ic_theme ic_needed ic_sys ic_broken ic_shot
  ic_theme="$(grep -A2 '^\[Icons\]' "$NEW_HOME/.config/kdeglobals" 2>/dev/null \
              | grep Theme= | cut -d= -f2 || true)"
  [[ -z "$ic_theme" ]] && ic_theme="$(grep -E '^icon_theme=' "$NEW_HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null | cut -d= -f2 || true)"
  # Sin ninguno de los dos: el tema que instala este rice.
  [[ -z "$ic_theme" ]] && ic_theme="$KS_DIR"

  ic_pkg() {
    case "$1" in
      Adwaita)                       echo "adwaita-icon-theme" ;;
      breeze*)                       echo "breeze-icons" ;;
      Papirus*)                      echo "papirus-icon-theme" ;;
      *)                             echo "" ;;
    esac
  }

  # Donde puede estar el tema. KrystalSVG va a ~/.local/share/icons porque no es
  # paquete: mirar solo /usr/share/icons lo hacia invisible para el instalador.
  ic_find() {
    local n="$1"
    [[ -d "/usr/share/icons/$n" ]] && { echo "/usr/share/icons/$n"; return 0; }
    [[ -d "$NEW_HOME/.local/share/icons/$n" ]] && { echo "$NEW_HOME/.local/share/icons/$n"; return 0; }
    echo ""
  }

  if [[ -z "$(ic_find "$ic_theme")" ]]; then
    ic_needed="$(ic_pkg "$ic_theme")"
    if [[ -n "$ic_needed" && $NO_PKGS -eq 0 && $NO_AUR -eq 0 && $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
      warn "$(T "Theme '$ic_theme' is missing; installing $ic_needed" "Falta el tema '$ic_theme'; se instalará $ic_needed")"
      if pacman -Si "$ic_needed" &>/dev/null; then
        as_root pacman -S --needed --noconfirm "$ic_needed" >/dev/null 2>&1 || true
      elif [[ -n "$AUR_HELPER" ]]; then
        mkdir -p "$AUR_LOG" 2>/dev/null || true
        "$AUR_HELPER" -S --needed --noconfirm "$ic_needed" >"$AUR_LOG/$ic_needed.log" 2>&1 || true
      fi
      pacman -Qq "$ic_needed" &>/dev/null && ok "$(T "$ic_needed installed" "$ic_needed instalado")" \
        || warn "$(T "$ic_needed could not be installed" "No se pudo instalar $ic_needed")"
    fi
  fi

  ic_sys="$(ic_find "$ic_theme")"
  if [[ -n "$ic_theme" && -n "$ic_sys" ]]; then
    set_gtk_icon_theme "$ic_theme"
    ic_sys="$ic_sys"
    ic_broken="$(grep -c '^Type=scalable' "$ic_sys/index.theme" 2>/dev/null || true)"
    ic_broken="${ic_broken:-0}"
    ic_shot="$(find "$ic_sys" -maxdepth 4 \( -name '*.png' -o -name '*.svg' \) -print -quit 2>/dev/null || true)"

    if [[ $DRY -eq 1 || $VERIFY_ONLY -eq 1 ]]; then
      if [[ "$ic_broken" -gt 0 ]]; then
        info "$(T "[dry-run] would patch ~/.local/share/icons/$ic_theme/index.theme ($ic_broken Type=scalable directories)" "[dry-run] se parchearía ~/.local/share/icons/$ic_theme/index.theme ($ic_broken directorios Type=scalable)")"
      else
        info "$(T "Qt6 can already read $ic_theme/index.theme" "Qt6 ya puede leer el index.theme de $ic_theme")"
      fi
    elif [[ "$ic_broken" -gt 0 ]]; then
      if fix_icon_index "$ic_theme"; then
        ok "$(T "$ic_theme/index.theme patched for Qt6 (Type=Scalable + MinSize/MaxSize)" "$ic_theme/index.theme parcheado para Qt6 (Type=Scalable + MinSize/MaxSize)")"
        info "    $(T "Without this, Qt searches for .svg, finds none, and silently falls back to hicolor" "Sin esto, Qt busca archivos .svg, no encuentra ninguno y usa hicolor sin avisar")"
      else
        warn "$(T "Could not patch $ic_theme/index.theme; Qt apps will use hicolor" "No se pudo parchear $ic_theme/index.theme; las aplicaciones Qt usarán hicolor")"
      fi
    else
      ok "$(T "Qt6 can already read $ic_theme/index.theme" "Qt6 ya puede leer el index.theme de $ic_theme")"
    fi
    [[ -z "$ic_shot" ]] && warn "$(T "Theme $ic_theme is empty: no PNG or SVG files under $ic_sys" "El tema $ic_theme está vacío: no hay archivos PNG ni SVG en $ic_sys")"
    if [[ $DRY -eq 0 && $VERIFY_ONLY -eq 0 && $USER_ONLY -eq 0 ]]; then
      as_root gtk-update-icon-cache -f -t "$ic_sys" >/dev/null 2>&1 || true
    fi
    if grep -qE "^icon_theme=$ic_theme$" "$NEW_HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null; then
      ok "$(T "qt6ct uses $ic_theme" "qt6ct usa $ic_theme")"
    else
      warn "$(T "qt6ct does not set icon_theme=$ic_theme; Qt apps may ignore it" "qt6ct no tiene icon_theme=$ic_theme; las aplicaciones Qt podrían ignorarlo")"
      info "    $(T "Qt reads the theme name from ~/.config/qt6ct/qt6ct.conf, not kdeglobals" "Qt obtiene el nombre del tema de ~/.config/qt6ct/qt6ct.conf, no de kdeglobals")"
    fi
    # Qt NO lee kdeglobals: lee ~/.config/qt6ct/qt6ct.conf. Si no se escribe ahi,
    # Dolphin y GTK quedan con el tema nuevo pero el lanzador de Noctalia (que es
    # Qt) se queda con el viejo. Por eso se sincronizan qt5ct y qt6ct ademas de
    # kdeglobals.
    if [[ $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
      kwriteconfig6 --file "$NEW_HOME/.config/kdeglobals" --group Icons \
        --key Theme "$ic_theme" >/dev/null 2>&1 || true
      for qtc in qt5ct/qt5ct.conf qt6ct/qt6ct.conf; do
        local f="$NEW_HOME/.config/$qtc"
        [[ -f $f ]] || continue
        if grep -qxF "icon_theme=$ic_theme" "$f" 2>/dev/null; then
          ok "$(T "$qtc uses $ic_theme" "$qtc usa $ic_theme")"
        elif sed -i "s|^icon_theme=.*|icon_theme=$ic_theme|" "$f" 2>/dev/null; then
          ok "$(T "$qtc set to $ic_theme" "$qtc puesto en $ic_theme")"
        else
          warn "$(T "Could not set icon_theme in $qtc" "No se pudo poner icon_theme en $qtc")"
        fi
      done
      kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    fi
  elif [[ -n "$ic_theme" ]]; then
    warn "$(T "Icon theme '$ic_theme' is NOT installed" "El tema de iconos '$ic_theme' NO está instalado")"
    info "    $(T "It ships as an asset of the Aeroctalia release; re-run without --no-packages" "Va como asset de la release de Aeroctalia; vuelve a ejecutar sin --no-packages")"
  fi
}

if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "--verify does not write files; inspection runs in step 12" "--verify no escribe archivos; la inspección se realiza en el paso 12")"
elif [[ $DRY -eq 1 ]]; then
  info "$(T "[dry-run] would rewrite the wrapper, .desktop, drop-in and environment.d, and patch the icon theme" "[dry-run] se reescribirían wrapper, .desktop, drop-in y environment.d, y se parchearía el tema de iconos")"
else
  rice_write_dolphin
  rice_fix_icons
  rice_generate_themes
fi


# ══════════════════════════════════════════════════════ 11. Ajustes ══════
step "$(T "Final settings" "Ajustes finales")"

set_default_cursor() {
  local theme="$1" f="/usr/share/icons/default/index.theme"
  if [[ -f "$f" ]] && grep -q '^Inherits=' "$f" 2>/dev/null; then
    as_root sed -i "s|^Inherits=.*|Inherits=$theme|" "$f" 2>/dev/null || return 1
    return 0
  fi
  printf '[Icon Theme]\nInherits=%s\n' "$theme" \
    | as_root tee "$f" >/dev/null 2>&1 || return 1
  return 0
}

cur_theme="$(grep -oP 'XCURSOR_THEME", "\K[^"]+' "$NEW_HOME/.config/hypr/hyprland.lua" 2>/dev/null || true)"
cur_size="$(grep -oP 'XCURSOR_SIZE", "\K[^"]+' "$NEW_HOME/.config/hypr/hyprland.lua" 2>/dev/null || true)"

if [[ $VERIFY_ONLY -eq 1 ]]; then
  info "$(T "Skipped (--verify)" "Omitido (--verify)")"
elif [[ -n "$cur_theme" && $USER_ONLY -eq 0 && $DRY -eq 0 ]]; then
  if [[ -d "/usr/share/icons/$cur_theme" ]]; then
    if set_default_cursor "$cur_theme"; then
      ok "$(T "System cursor → $cur_theme" "Cursor del sistema → $cur_theme")"
    else
      warn "$(T "Could not edit /usr/share/icons/default/index.theme" "No se pudo editar /usr/share/icons/default/index.theme")"
    fi
    printf '[Icon Theme]\nInherits=%s\n' "$cur_theme" \
      | as_root tee /usr/share/icons/default/cursor.theme >/dev/null 2>&1 \
      && ok "$(T "cursor.theme written (reinforcement; not owned by a package)" "cursor.theme escrito (refuerzo; no pertenece a ningún paquete)")" \
      || warn "$(T "Could not write cursor.theme" "No se pudo escribir cursor.theme")"
    as_root mkdir -p /etc/pacman.d/hooks 2>/dev/null || true
    hook_txt="$(cat <<'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = /usr/share/icons/default/index.theme
Target = /usr/share/icons/__THEME__

[Action]
Description = Volver a poner __THEME__ como cursor del login (default-cursors pisa index.theme)
When = PostTransaction
Exec = /bin/sh -c 'f=/usr/share/icons/default/index.theme; [ -f "$f" ] || exit 0; if grep -q "^Inherits=" "$f"; then sed -i "s|^Inherits=.*|Inherits=__THEME__|" "$f"; else printf "[Icon Theme]\nInherits=__THEME__\n" >"$f"; fi'
HOOK
)"
    hook_txt="${hook_txt//__THEME__/$cur_theme}"
    if printf '%s\n' "$hook_txt" | grep -q "__THEME__"; then
      warn "$(T "The pacman hook still contains an unreplaced theme placeholder; not writing it" "El hook de pacman aún tiene el marcador del tema sin reemplazar; no se escribirá")"
    else
      printf '%s\n' "$hook_txt" \
        | as_root tee /etc/pacman.d/hooks/rice-cursor.hook >/dev/null 2>&1 \
        && ok "$(T "pacman hook written (a system upgrade will not reset the cursor to Adwaita)" "Hook de pacman escrito (una actualización no volverá a poner Adwaita como cursor)")" \
        || warn "$(T "Could not write rice-cursor.hook" "No se pudo escribir rice-cursor.hook")"
    fi
    as_root mkdir -p /etc/systemd/system/sddm-greeter.service.d 2>/dev/null || true
    printf '[Service]\nEnvironment=XCURSOR_THEME=%s\nEnvironment=XCURSOR_SIZE=%s\n' \
      "$cur_theme" "${cur_size:-24}" \
      | as_root tee /etc/systemd/system/sddm-greeter.service.d/cursor.conf >/dev/null 2>&1 \
      && ok "$(T "sddm-greeter drop-in written" "Drop-in de sddm-greeter escrito")"
    as_root systemctl daemon-reload >/dev/null 2>&1 || true
  else
    warn "$(T "Cursor theme '$cur_theme' is not installed" "El tema de cursor '$cur_theme' no está instalado")"
  fi
elif [[ -n "$cur_theme" && $DRY -eq 1 ]]; then
  info "$(T "[dry-run] would set $cur_theme as the system cursor" "[dry-run] se establecería $cur_theme como cursor del sistema")"
fi

cur_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
if [[ $VERIFY_ONLY -eq 1 ]]; then
  :
elif [[ "$cur_shell" == */zsh ]]; then
  ok "$(T "Shell: $cur_shell" "Shell: $cur_shell")"
elif command -v zsh >/dev/null 2>&1; then
  if [[ $DRY -eq 1 ]]; then
    info "$(T "[dry-run] would change the shell to /bin/zsh (currently $cur_shell)" "[dry-run] se cambiaría el shell a /bin/zsh (actual: $cur_shell)")"
  elif as_root chsh -s /bin/zsh "$(id -un)" 2>/dev/null; then
    ok "$(T "Shell changed to /bin/zsh (log out and back in)" "Shell cambiado a /bin/zsh (cierra sesión y vuelve a entrar)")"
  else
    warn "$(T "Could not change the shell to zsh; run manually:" "No se pudo cambiar el shell a zsh; ejecuta manualmente:")  chsh -s /bin/zsh $(id -un)"
  fi
else
  warn "$(T "zsh is not installed; login shell remains" "zsh no está instalado; el shell de inicio sigue siendo") $cur_shell"
fi

if [[ $DRY -eq 0 && $VERIFY_ONLY -eq 0 ]]; then
  [[ $USER_ONLY -eq 0 ]] && { as_root systemctl daemon-reload || true; }
  systemctl --user daemon-reload 2>/dev/null || true
  for u in "$NEW_HOME"/.config/systemd/user/*.service; do
    [[ -f "$u" ]] || continue
    name="$(basename "$u")"
    grep -q "\[Install\]" "$u" || continue
    systemctl --user enable "$name" 2>/dev/null && ok "$(T "Enabled $name" "Se habilitó $name")" || true
  done
  fc-cache -f >/dev/null 2>&1 || true
  for d in "$NEW_HOME/.icons" "$NEW_HOME/.local/share/icons" "$NEW_HOME/.themes"; do
    [[ -d "$d" ]] && gtk-update-icon-cache -fqt "$d" >/dev/null 2>&1 || true
  done
  ok "$(T "Caches refreshed (fonts, icons)" "Cachés regeneradas (fuentes, iconos)")"
fi

# ══════════════════════════════════════════════════════ 12. Verificación ═
do_verify() {
  printf '\n'
  step "$(T "Verification" "Verificación")"
  local problems=0
  local vs want_icon v_sys v_usr v_hom v_where v_idx v_bad v_dirs v_colgados v_total v_img gtk_gsettings_icon sound_asset
  local wp wallpaper_dir theme_settings theme_source theme_scheme nf live wrap desk drop envd resolved

  vs="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
  if [[ "$vs" == */zsh ]]; then ok "$(T "Shell: zsh" "Shell: zsh")"
  else warn "$(T "Shell: $vs (not zsh); prompt and aliases are unavailable" "Shell: $vs (no es zsh); el prompt y los alias no se aplican")"; problems=$((problems+1)); fi

  if [[ "$DM" == "sddm" ]]; then
    sound_asset="$REPO/assets/sddm/win7-sddm-theme/Assets/Startup-Sound.wav"
    if [[ -f "$sound_asset" ]]; then
      ok "$(T "SDDM startup sound asset is present" "El sonido de inicio de SDDM está presente")"
    else
      warn "$(T "SDDM startup sound asset is missing: $sound_asset" "Falta el sonido de inicio de SDDM: $sound_asset")"
      problems=$((problems+1))
    fi
    for p in qt6-multimedia qt6-multimedia-ffmpeg pipewire wireplumber; do
      if pacman -Qq "$p" >/dev/null 2>&1; then
        ok "$(T "SDDM audio dependency installed:" "Dependencia de audio de SDDM instalada:") $p"
      else
        warn "$(T "SDDM audio dependency is missing:" "Falta una dependencia de audio de SDDM:") $p"
        problems=$((problems+1))
      fi
    done
    sddm_audio_group || problems=$((problems+1))
    sddm_audio_early_start || problems=$((problems+1))
  fi

  # ── iconos ──
  want_icon="$(grep -A2 '^\[Icons\]' "$NEW_HOME/.config/kdeglobals" 2>/dev/null \
               | grep Theme= | cut -d= -f2 || true)"
  [[ -z "$want_icon" ]] && want_icon="$(grep -E '^icon_theme=' "$NEW_HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null | cut -d= -f2 || true)"
  if [[ -z "$want_icon" ]]; then
    warn "$(T "Icon theme not found in kdeglobals or qt6ct" "No se encontró el tema de iconos en kdeglobals ni qt6ct")"
  else
    if [[ "$NEW_HOME" == "$HOME" ]] && command -v gsettings >/dev/null 2>&1; then
      gtk_gsettings_icon="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'\"" || true)"
      if [[ -z "$gtk_gsettings_icon" ]]; then
        info "$(T "Could not query GTK GSettings icon theme in this session." "No se pudo consultar el tema de iconos GSettings de GTK en esta sesión.")"
      elif [[ "$gtk_gsettings_icon" == "$want_icon" ]]; then
        ok "$(T "GTK GSettings icon theme: $gtk_gsettings_icon" "Tema de iconos GTK GSettings: $gtk_gsettings_icon")"
      else
        warn "$(T "GTK GSettings uses $gtk_gsettings_icon; expected $want_icon. Try: gsettings set org.gnome.desktop.interface icon-theme '$want_icon'" "GTK GSettings usa $gtk_gsettings_icon; se esperaba $want_icon. Prueba: gsettings set org.gnome.desktop.interface icon-theme '$want_icon'")"
        problems=$((problems+1))
      fi
    fi
    v_sys="/usr/share/icons/$want_icon"
    v_usr="$NEW_HOME/.local/share/icons/$want_icon"
    v_hom="$NEW_HOME/.icons/$want_icon"
    v_where=""
    local d
    for d in "$v_usr" "$v_hom" "$v_sys"; do
      [[ -d "$d" ]] && { v_where="$d"; break; }
    done
    if [[ -z "$v_where" ]]; then
      warn "$(T "Icon theme '$want_icon' is NOT installed" "El tema de iconos '$want_icon' NO está instalado")"
      info "    $(T "it ships as an asset of the Aeroctalia release" "va como asset de la release de Aeroctalia")"
      problems=$((problems+1))
    else
      v_idx=""
      local i
      for i in "$v_usr/index.theme" "$v_hom/index.theme" "$v_sys/index.theme"; do
        [[ -f "$i" ]] && { v_idx="$i"; break; }
      done
      ok "$(T "Icon theme: $want_icon  ($v_where)" "Tema de iconos: $want_icon  ($v_where)")"
      v_bad="$(grep -c '^Type=scalable' "$v_idx" 2>/dev/null || true)"; v_bad="${v_bad:-0}"
      if [[ "$v_bad" -gt 0 ]]; then
        warn "$(T "index.theme has $v_bad lowercase Type=scalable entries; Qt6 falls back to hicolor" "index.theme tiene $v_bad entradas Type=scalable en minúscula; Qt6 usa hicolor")"
        info "    ./install.sh --no-packages"
        problems=$((problems+1))
      else
        ok "$(T "index.theme is readable by Qt6" "index.theme es legible por Qt6")"
      fi
      v_dirs="$(sed -n 's/^Directories=//p' "$v_idx" 2>/dev/null \
                | tr ',' '\n' | sed 's#/.*##' | sed '/^[[:space:]]*$/d' | sort -u || true)"
      v_colgados=0
      local sub
      for sub in $v_dirs; do
        [[ -e "$v_where/$sub" ]] && v_colgados=$((v_colgados+1))
      done
      v_total="$(printf '%s\n' "$v_dirs" | grep -c . || true)"
      if [[ "${v_total:-0}" -gt 0 && "${v_colgados:-0}" -lt "${v_total:-0}" ]]; then
        warn "$(T "$((v_total - v_colgados)) of $v_total linked directories are missing under $v_where" "Faltan $((v_total - v_colgados)) de $v_total directorios enlazados en $v_where")"
        problems=$((problems+1))
      fi
      v_img="$(find -L "$v_where" -maxdepth 4 \( -name '*.png' -o -name '*.svg' -o -name '*.xpm' \) -print -quit 2>/dev/null || true)"
      if [[ -z "$v_img" ]]; then
        warn "$(T "The theme is empty (use find -L; theme directories are symlinks)" "El tema está vacío (usa find -L; sus directorios usan symlinks)")"
        problems=$((problems+1))
      else
        info "    $(find -L "$v_where" -name '*.png' 2>/dev/null | wc -l) PNG, $(find -L "$v_where" -name '*.svg' 2>/dev/null | wc -l) SVG"
      fi
    fi
  fi

  # ── los 3 caminos de Dolphin ──
  info ""
  info "$(T "Dolphin: three launch paths (docs/DOLPHIN.md):" "Dolphin: tres rutas de inicio (docs/DOLPHIN.md):")"
  wrap="$NEW_HOME/.local/bin/dolphin"
  if [[ -x "$wrap" ]] && grep -q 'QT_STYLE_OVERRIDE' "$wrap" && grep -q 'QT_QPA_PLATFORMTHEME' "$wrap"; then
    ok "$(T "path 1  wrapper  SUPER+E / terminal" "ruta 1  wrapper  SUPER+E / terminal")"
  else
    warn "$(T "path 1  incomplete wrapper ($wrap)" "ruta 1  wrapper incompleto ($wrap)")"
    problems=$((problems+1))
  fi
  PATH="$NEW_HOME/.local/bin:$PATH"
  resolved="$(command -v dolphin 2>/dev/null || true)"
  [[ "$resolved" == "$wrap" ]] && ok "         command -v dolphin → $(T "wrapper" "wrapper")" \
    || { warn "         command -v dolphin → ${resolved:-?}"; }

  desk="$NEW_HOME/.local/share/applications/org.kde.dolphin.desktop"
  if [[ -f "$desk" ]] && grep -q 'QT_STYLE_OVERRIDE' "$desk"; then
    ok "$(T "path 2  .desktop  menu / krunner / gio" "ruta 2  .desktop  menú / krunner / gio")"
  else
    warn "$(T "path 2  .desktop has no Kvantum overlay" "ruta 2  .desktop sin overlay de Kvantum")"
    problems=$((problems+1))
  fi

  drop="$NEW_HOME/.config/systemd/user/plasma-dolphin.service.d/kvantum.conf"
  if [[ -f "$drop" ]] && grep -q 'QT_STYLE_OVERRIDE=kvantum' "$drop" && grep -q 'QT_QPA_PLATFORMTHEME' "$drop"; then
    ok "$(T "path 3  drop-in   browser (D-Bus FileManager1)" "ruta 3  drop-in   navegador (D-Bus FileManager1)")"
  else
    warn "$(T "path 3  incomplete drop-in; 'show in folder' has no theme" "ruta 3  drop-in incompleto; 'mostrar en carpeta' aparece sin tema")"
    problems=$((problems+1))
  fi

  envd="$NEW_HOME/.config/environment.d/50-rice.conf"
  [[ -f "$envd" ]] && ok "$(T "environment.d/50-rice.conf is present" "environment.d/50-rice.conf está presente")" \
    || { warn "$(T "environment.d/50-rice.conf is missing" "Falta environment.d/50-rice.conf")"; problems=$((problems+1)); }
  live="$(systemctl --user show-environment 2>/dev/null | grep '^QT_QPA_PLATFORMTHEME=' || true)"
  if [[ "$live" == *qt6ct* ]]; then
    ok "$(T "Current session:" "Sesión actual:") $live"
  else
    info "$(T "QT_QPA_PLATFORMTHEME is empty in systemd; this is expected until the next login" "QT_QPA_PLATFORMTHEME está vacío en systemd; es normal hasta el próximo inicio de sesión")"
  fi

  if [[ -f "$NEW_HOME/.config/hypr/hyprland.lua" ]] && \
     grep -qE 'fileManager = "/home/[^"]+/.local/bin/dolphin"' "$NEW_HOME/.config/hypr/hyprland.lua"; then
    warn "$(T "hyprland.lua has a hardcoded HOME; SUPER+E points to another machine" "hyprland.lua tiene un HOME fijo; SUPER+E apunta a otra máquina")"
    problems=$((problems+1))
  fi

  if [[ -z "${QT_QPA_PLATFORMTHEME:-}" ]]; then
    if grep -q 'QT_QPA_PLATFORMTHEME' "$NEW_HOME/.config/hypr/hyprland.lua" 2>/dev/null; then
      info "$(T "QT_QPA_PLATFORMTHEME is empty in this shell; Hyprland exports it to its child processes" "QT_QPA_PLATFORMTHEME está vacío en esta shell; Hyprland lo exporta a sus procesos hijos")"
    else
      warn "$(T "hyprland.lua does NOT export QT_QPA_PLATFORMTHEME" "hyprland.lua NO exporta QT_QPA_PLATFORMTHEME")"
      problems=$((problems+1))
    fi
  elif [[ "${QT_QPA_PLATFORMTHEME}" == "qt6ct" ]]; then
    ok "$(T "QT_QPA_PLATFORMTHEME=qt6ct (this shell)" "QT_QPA_PLATFORMTHEME=qt6ct (esta shell)")"
  fi

  if [[ -f "$NEW_HOME/.local/state/noctalia/settings.toml" ]]; then
    ok "$(T "Noctalia: settings.toml is present" "Noctalia: settings.toml está presente")"
    wallpaper_dir="$(awk '
      /^\[wallpaper\]$/ { in_wallpaper=1; next }
      /^\[/ { in_wallpaper=0 }
      in_wallpaper && /^directory[[:space:]]*=/ { sub(/^[^\"]*\"/, ""); sub(/\".*$/, ""); print; exit }
    ' "$NEW_HOME/.local/state/noctalia/settings.toml" 2>/dev/null || true)"
    if [[ -z "$wallpaper_dir" || "$wallpaper_dir" == *'$HOME'* || "$wallpaper_dir" == *'${HOME}'* ]]; then
      warn "$(T "Noctalia wallpaper directory is missing or contains an unexpanded HOME placeholder." "El directorio de wallpapers de Noctalia falta o contiene un marcador HOME sin expandir.")"
      problems=$((problems+1))
    elif [[ -d "$wallpaper_dir" ]]; then
      ok "$(T "Noctalia wallpaper directory:" "Directorio de wallpapers de Noctalia:") $wallpaper_dir"
    else
      warn "$(T "Noctalia wallpaper directory does not exist:" "No existe el directorio de wallpapers de Noctalia:") $wallpaper_dir"
      problems=$((problems+1))
    fi

    theme_settings="$(sed -n '/^\[theme\]$/,/^\[/p' "$NEW_HOME/.local/state/noctalia/settings.toml" 2>/dev/null || true)"
    theme_source="$(sed -n 's/^source = "\([^"]*\)"/\1/p' <<<"$theme_settings" | head -1)"
    theme_scheme="$(sed -n 's/^wallpaper_scheme = "\([^"]*\)"/\1/p' <<<"$theme_settings" | head -1)"
    if [[ "$theme_source" == "wallpaper" && "$theme_scheme" == "m3-content" ]]; then
      ok "$(T "Noctalia palette uses M3 Content from the wallpaper." "La paleta de Noctalia usa M3 Content a partir del wallpaper.")"
    else
      warn "$(T "Noctalia is not configured for wallpaper-based M3 Content (source=$theme_source, scheme=$theme_scheme)." "Noctalia no está configurado para M3 Content desde el wallpaper (source=$theme_source, scheme=$theme_scheme).")"
      problems=$((problems+1))
    fi
  else
    warn "$(T "~/.local/state/noctalia/settings.toml was not found" "No se encontró ~/.local/state/noctalia/settings.toml")"
    problems=$((problems+1))
  fi

 
  wp="$(grep -A2 '^[[:space:]]*\[wallpaper\.default\]' \
        "$NEW_HOME/.local/state/noctalia/settings.toml" 2>/dev/null \
        | grep -E 'path[[:space:]]*=' | cut -d'"' -f2 || true)"
  if [[ -n "$wp" ]]; then
    if [[ "$wp" == *'$HOME'* || "$wp" == *'${HOME}'* ]]; then
      warn "$(T "Wallpaper path contains an unexpanded HOME placeholder:" "La ruta del wallpaper contiene un marcador HOME sin expandir:") $wp"
      problems=$((problems+1))
    elif [[ -e "$wp" ]]; then
      ok "$(T "Wallpaper:" "Wallpaper:") $(basename "$wp")"
    else
      warn "$(T "Wallpaper does not exist:" "El wallpaper no existe:") $wp"
      problems=$((problems+1))
    fi
  else
    warn "$(T "No default wallpaper is assigned in Noctalia." "No hay un wallpaper predeterminado asignado en Noctalia.")"
    problems=$((problems+1))
  fi

  nf="$(fc-list 2>/dev/null | grep -ci nerd || true)"
  if [[ "${nf:-0}" -gt 50 ]]; then ok "$(T "Nerd fonts: $nf" "Fuentes Nerd: $nf")"
  else warn "$(T "Only $nf Nerd fonts found (expected >50)" "Solo se encontraron $nf fuentes Nerd (se esperaban >50)")"; fi

  local m
  for m in noctalia monitors; do
    if [[ -f "$NEW_HOME/.config/hypr/$m.lua" ]]; then
      ok "$(T "Hyprland: $m.lua is present" "Hyprland: $m.lua está presente")"
    else
      warn "$(T "Hyprland: $m.lua is missing (generated by another tool)" "Hyprland: falta $m.lua (lo genera otra herramienta)")"
    fi
  done
  if grep -qE '^[[:space:]]*require\("noctalia"\)' "$NEW_HOME/.config/hypr/hyprland.lua" 2>/dev/null; then
    warn "$(T "hyprland.lua calls require(\"noctalia\") without pcall" "hyprland.lua tiene require(\"noctalia\") sin pcall")"
  fi

  if [[ -n "${cur_theme:-}" ]]; then
    local cur_sys
    cur_sys="$(grep -h '^Inherits=' /usr/share/icons/default/index.theme 2>/dev/null | tail -1 | cut -d= -f2 || true)"
    if [[ "$cur_sys" == "$cur_theme" ]]; then
      ok "$(T "Login cursor: $cur_sys" "Cursor de inicio: $cur_sys")"
    else
      warn "$(T "Login cursor is '$cur_sys', not '$cur_theme'" "El cursor de inicio es '$cur_sys', no '$cur_theme'")"
      problems=$((problems+1))
    fi
    [[ -f /etc/pacman.d/hooks/rice-cursor.hook ]] \
      && ok "$(T "pacman hook is present (default-cursors will not override the cursor)" "El hook de pacman está presente (default-cursors no reemplazará el cursor)")" \
      || warn "$(T "No pacman hook; a -Syu may reset the login cursor to Adwaita" "Sin hook de pacman; un -Syu puede restablecer el cursor a Adwaita")"
  fi

  # sonda Qt opcional
  if [[ $DRY -eq 0 && -x "$REPO/tools/qt-icon-probe.sh" ]] \
     && command -v g++ >/dev/null && pkg-config --exists Qt6Gui 2>/dev/null; then
    info "$(T "Qt6 probe (the theme actually resolved, not package metadata):" "Sonda Qt6 (el tema que realmente resolvió, no lo que indica el paquete):")"
    if "$REPO/tools/qt-icon-probe.sh" "${want_icon:-$KS_DIR}"; then
      ok "$(T "Probe: icons are loaded from the theme" "Sonda: los iconos se cargan desde el tema")"
    else
      warn "$(T "Probe: Qt is not rendering $want_icon (falling back to hicolor)" "Sonda: Qt no está mostrando $want_icon (usa hicolor)")"
      problems=$((problems+1))
    fi
  else
    info "$(T "For an actual icon rendering test: ./tools/qt-icon-probe.sh (g++ + qt6-base)" "Para probar la renderización real de iconos: ./tools/qt-icon-probe.sh (g++ + qt6-base)")"
    info "$(T "Or: ./tools/verify-dolphin.sh --probe" "O: ./tools/verify-dolphin.sh --probe")"
  fi

  if [[ $problems -gt 0 ]]; then
    echo
    warn "$(T "$problems issue(s) to review; see docs/DOLPHIN.md and docs/MANUAL.md" "$problems cosa(s) para revisar; consulta docs/DOLPHIN.md y docs/MANUAL.md")"
    info "$(T "Many issues are fixed by restarting the session" "Muchas cosas se solucionan reiniciando la sesión")"
    printf '\n%s\n' "$(T "Result: FAILED" "Resultado: FALLÓ")"
  else
    ok "$(T "Everything verified" "Todo verificado")"
    printf '\n%s\n' "$(T "Result: PASS" "Resultado: CORRECTO")"
  fi
  return 0
}

do_verify

if [[ $DRY -eq 0 && $USER_ONLY -eq 0 && "$DM" != "none" && $VERIFY_ONLY -eq 0 ]]; then
  printf '\n'
  dm_on="$(systemctl is-enabled "$DM" 2>/dev/null || echo '?' )"
  tgt="$(systemctl get-default 2>/dev/null || echo '?')"
  if [[ "$dm_on" == "enabled" && "$tgt" == "graphical.target" ]]; then
    ok "$(T "Login: $DM enabled, target $tgt" "Inicio de sesión: $DM habilitado, objetivo $tgt")"
  else
    warn "$(T "Login is NOT configured correctly ($DM=$dm_on, target=$tgt)" "El inicio de sesión NO quedó bien ($DM=$dm_on, objetivo=$tgt)")"
    info "$(T "From a TTY:" "Desde una TTY:")  systemctl enable sddm && systemctl set-default graphical.target && reboot"
  fi
fi

echo
printf '%s── %s · %ss · v%s ──%s\n' "$G" "$(T "done" "listo")" "$SECONDS" "$RICE_VERSION" "$N"
[[ -d "$STASH" ]] && info "$(T "Previous files:" "Archivos anteriores:") $STASH"
info "Log: $LOG"
echo
if [[ $VERIFY_ONLY -eq 0 ]]; then
  info "$(T "Manual steps remaining:" "Pasos manuales pendientes:")"
  if [[ $USER_ONLY -eq 0 ]]; then
    info "  · sudo mkinitcpio -P          # $(T "if /etc/mkinitcpio.conf was changed" "si se modificó /etc/mkinitcpio.conf")"
    info "  · sudo grub-mkconfig -o /boot/grub/grub.cfg   # $(T "if you use GRUB" "si usas GRUB")"
    info "  · $(T "review" "revisa") /etc/fstab $(T "and" "y") /etc/crypttab"
  else
    info "  · $(T "run again without --user-only to modify /etc" "vuelve a ejecutar sin --user-only para modificar /etc")"
  fi
  info "  · $(T "log out and back in (Hyprland reads configuration at startup)" "cierra sesión y vuelve a entrar (Hyprland carga la configuración al iniciar)")"
  info "  · $(T "check monitor layout with nwg-displays if it does not match" "revisa los monitores con nwg-displays si no coinciden")"
  echo
  info "$(T "Dolphin / icons:" "Dolphin / iconos:")"
  info "  ./tools/verify-dolphin.sh --probe"
fi
[[ $DRY -eq 1 && $VERIFY_ONLY -eq 0 ]] && echo && say "$(T "This was a DRY RUN: no changes were made." "Esto fue un DRY-RUN: no se cambió nada.")"
[[ $VERIFY_ONLY -eq 1 ]] && say "$(T "This was --verify: no changes were made." "Esto fue --verify: no se cambió nada.")"
INSTALL_SUCCESS=1
exit 0