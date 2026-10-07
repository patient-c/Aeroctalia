# ~/.config/zsh/aeroctalia-themes.zsh — sourceado desde ~/.zshrc
#
# Colores del prompt y de las herramientas siguiendo la paleta que Noctalia
# genera del wallpaper. Todo lo de aqui se regenera solo; ver el bloque de
# hooks en ~/.config/noctalia/animfetch.toml.
#
# Los generadores, en ~/.local/bin/:
#   noctalia-animfetch-palette  ->  ~/.config/animfetch/palette.json
#   noctalia-shell-theme        ->  el .omp.json, lscolors, grep_colors y el
#                                   tema de bat, todos desde esa paleta

# ══ animfetch: fetch animado fijo arriba del prompt (--pin) ═════════════════
#
# Nunca `animfetch` a secas: su modo por defecto es interactivo, se queda
# esperando entrada y bloquea todo el resto del .zshrc.
#
# OJO: no redirijas la salida de `animfetch --unpin`. Si stdout no es una tty
# cae al modo estatico y no desarma nada.
af_pin() { command animfetch --pin -a dolphin-swim && ANIMFETCH_PINNED=1 }
af_unpin() { command animfetch --unpin; ANIMFETCH_PINNED=0 }

# `clear` y Ctrl+L desarman el pin para dejar la pantalla limpia de verdad.
clear() {
  (( ${+ANIMFETCH_PINNED} )) && (( ANIMFETCH_PINNED )) && af_unpin
  command clear "$@"
}

# Ctrl+L: ejecuta `clear` como comando normal. Dentro de un widget de zle
# `animfetch --unpin` no hace nada, de ahi el push-line + accept-line.
_af_clear_widget() {
  zle push-line
  zle -U $'clear\n'
  zle accept-line
}
zle -N _af_clear_widget 2>/dev/null
bindkey '^L' _af_clear_widget 2>/dev/null

# ══ Colores de ls / grep: los relee el precmd cuando cambian ═══════════════
#
# Asi las terminales YA abiertas cambian de color sin abrir otra: LS_COLORS y
# GREP_COLORS los lee cada ejecucion de ls/grep, asi que basta con reexportar.
typeset -gA _noctalia_mtime
_noctalia_sync() {
  local f t name val
  for f in "$HOME/.config/animfetch/lscolors" "$HOME/.config/animfetch/grep_colors"; do
    [[ -r $f ]] || continue
    name=${f:t}
    # zstat da el mtime en segundos; si no esta el modulo, se relee siempre.
    t=$(zstat -L +mtime -- $f 2>/dev/null) || t=
    if [[ -n $t && $t == ${_noctalia_mtime[$name]-} ]]; then continue; fi
    [[ -z $t ]] || _noctalia_mtime[$name]=$t
    val=$(<$f) || continue
    case $name in
      lscolors)    [[ -n $val ]] && export LS_COLORS=$val ;;
      grep_colors) [[ -n $val ]] && export GREP_COLORS=$val ;;
    esac
  done
  return 0
}

zmodload -F zsh/stat b:zstat 2>/dev/null
autoload -Uz add-zsh-hook
add-zsh-hook precmd _noctalia_sync
_noctalia_sync

# ══ oh-my-posh ════════════════════════════════════════════════════════════
export OMP_CONFIG="$HOME/.config/oh-my-posh/paradox-noctalia.omp.json"
[[ -f $OMP_CONFIG ]] || command ~/.local/bin/noctalia-shell-theme 2>/dev/null

# oh-my-posh guarda el tema en memoria: tras un cambio de paleta hace falta
# omp_reload para aplicarlo a ESTA terminal sin abrir otra.
omp_reload() {
  command ~/.local/bin/noctalia-shell-theme omp
  eval "$(oh-my-posh init zsh --config $OMP_CONFIG)"
}

# ══ grep y bat ════════════════════════════════════════════════════════════
# Los tonos vienen de GREP_COLORS; --color=auto lo decide la salida.
alias grep="grep --color=auto"

# bat usa el tema que genera noctalia-shell-theme. Sin esto habria que pasarlo
# con --theme en cada llamada, y ademas bat cachea los temas de usuario en un
# binario aparte que hay que reconstruir (lo hace el generador).
export BAT_THEME="noctalia"

# man: sale con la paleta (man -> col quita sobreescritos -> bat colorea).
# Descomentar si tienes man-db instalado.
# export MANPAGER="sh -c 'col -bx | bat --language=man --paging=always --style=plain -r'"

# ══ Arranque ═══════════════════════════════════════════════════════════════
if [[ $- == *i* ]] && command -v animfetch >/dev/null 2>&1 \
   && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config $OMP_CONFIG)" 2>/dev/null
  af_pin
fi