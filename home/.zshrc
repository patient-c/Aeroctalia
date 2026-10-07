# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change the frequency the auto-updater is run (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line to set how old an update must be before it's applied, manually or via the auto-updater (in days).
# zstyle ':omz:update' cooldown 10

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
         zsh-syntax-highlighting
         sudo
         zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# Buscar e instalar paquetes oficiales con fzf
pkg-install() {
  local pkg
  pkg=$(pacman -Slq | fzf \
    --multi \
    --preview 'pacman -Sii {1}' \
    --preview-window 'right:60%:wrap' \
    --prompt 'Repo> ')
  [[ -n "$pkg" ]] && sudo pacman -S ${(f)pkg}
}

# Buscar e instalar paquetes de AUR con fzf
pkg-aur-install() {
  local pkg
  pkg=$(yay -Slq --aur | fzf \
    --multi \
    --preview 'yay -Si {1}' \
    --preview-window 'right:60%:wrap' \
    --prompt 'AUR> ')
  [[ -n "$pkg" ]] && yay -S ${(f)pkg}
}

export LS_COLORS="di=1;38;5;75:ln=38;5;80:so=38;5;141:pi=38;5;222:ex=1;38;5;42:bd=1;38;5;215:cd=1;38;5;215:su=48;5;124;38;5;255:sg=48;5;179;38;5;235:tw=48;5;73;38;5;235:ow=48;5;75;38;5;255:st=48;5;60;38;5;255:mi=38;5;244:or=38;5;203:*.tar=38;5;203:*.tgz=38;5;203:*.gz=38;5;203:*.zip=38;5;203:*.rar=38;5;203:*.7z=38;5;203:*.bz2=38;5;203:*.xz=38;5;203:*.deb=38;5;203:*.rpm=38;5;203:*.jpg=38;5;80:*.jpeg=38;5;80:*.png=38;5;80:*.gif=38;5;80:*.bmp=38;5;80:*.svg=38;5;80:*.webp=38;5;80:*.ico=38;5;80:*.mp4=38;5;75:*.mkv=38;5;75:*.avi=38;5;75:*.mov=38;5;75:*.webm=38;5;75:*.flv=38;5;75:*.mp3=38;5;147:*.flac=38;5;147:*.wav=38;5;147:*.ogg=38;5;147:*.m4a=38;5;147:*.pdf=38;5;222:*.doc=38;5;222:*.docx=38;5;222:*.xls=38;5;222:*.xlsx=38;5;222:*.ppt=38;5;222:*.pptx=38;5;222:*.txt=38;5;253:*.md=38;5;253:*.log=38;5;245:*.conf=38;5;79:*.json=38;5;79:*.yaml=38;5;79:*.yml=38;5;79:*.xml=38;5;79:*.sh=1;38;5;75:*.py=38;5;74:*.js=38;5;221:*.php=38;5;80:*.sql=38;5;73:*.bak=38;5;244:*.tmp=38;5;244:*.swp=38;5;244:"

alias ls="lsd"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat --style=plain"

# Logo aleatorio (Frutiger Aero) al iniciar fastfetch: apunta al wrapper
# ~/.config/fastfetch/random-logo.sh, que elige un PNG al azar de
# ~/.config/fastfetch/logos/ y llama al fastfetch real con ese logo.
alias fastfetch="~/.config/fastfetch/random-logo.sh"

fastfetch

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


export PATH="$HOME/.local/bin:$PATH"

# Colores que siguen a la paleta del wallpaper: prompt, ls, grep y bat.
# El prompt se inicializa ahi, no en la linea de abajo.
[[ -r "$HOME/.config/zsh/aeroctalia-themes.zsh" ]] \
  && source "$HOME/.config/zsh/aeroctalia-themes.zsh"

# opencode
if [[ -d "$HOME/.opencode/bin" ]]; then
  export PATH="$HOME/.opencode/bin:$PATH"
fi
