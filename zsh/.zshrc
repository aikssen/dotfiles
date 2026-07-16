# ~/.zshrc — configuracion de zsh (versionada en ~/dotfiles, multiplataforma).
# Prompt: starship | Plugins: antidote (fuera de Warp) | ls: eza

export HOMEBREW_NO_AUTO_UPDATE=1

# Raiz del repo dotfiles, derivada del propio symlink de este archivo.
# Funciona sin importar donde se haya clonado (~/dotfiles, ~/Documents/DEV/dotfiles, etc.).
# %x = archivo que se esta sourceando (~/.zshrc, symlink) | :A resuelve el symlink | :h:h sube dos niveles
export DOTFILES="${${(%):-%x}:A:h:h}"

# ----------------------------------------------------------------------------
# PATH
# ----------------------------------------------------------------------------
# ~/.local/bin primero (herramientas user-local en Linux y macOS).
# Debe ir ANTES de los init de zoxide/starship/mise para que se encuentren.
export PATH="$HOME/.local/bin:$PATH"

# Paths especificos de macOS — solo si existen (portable a Linux)
[ -d "/usr/local/opt/python/libexec/bin" ] && export PATH="/usr/local/opt/python/libexec/bin:$PATH"
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
[ -d "$HOME/.mavis/bin" ]    && export PATH="$HOME/.mavis/bin:$PATH"

# ----------------------------------------------------------------------------
# Historial
# ----------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# ----------------------------------------------------------------------------
# Completions (en todas las terminales; -C salta el chequeo lento de seguridad)
# ----------------------------------------------------------------------------
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive

# ----------------------------------------------------------------------------
# Plugins (antidote) — SOLO fuera de Warp.
# Warp trae autosuggestions/syntax-highlighting nativos y los plugins ZLE
# chocarian con su editor de linea. Fuera de Warp (SSH a Linux, otras
# terminales) si los cargamos.
# ----------------------------------------------------------------------------
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  ANTIDOTE=""
  if command -v brew >/dev/null 2>&1 && [ -f "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh" ]; then
    ANTIDOTE="$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  elif [ -f "$HOME/.antidote/antidote.zsh" ]; then
    ANTIDOTE="$HOME/.antidote/antidote.zsh"
  fi
  if [ -n "$ANTIDOTE" ]; then
    source "$ANTIDOTE"
    antidote load "$HOME/.zsh_plugins.txt"
    # history-substring-search con flechas
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
  fi
fi

# ----------------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
else
  alias ll='ls -lah'
  alias la='ls -A'
fi

alias ff='fastfetch'

# Guardar/actualizar estos dotfiles en un solo comando
alias dotsave='git -C "$DOTFILES" add -A && git -C "$DOTFILES" commit -m "update dotfiles" && git -C "$DOTFILES" push'

# Yazi: 'y' abre el explorador y al salir (q) deja la shell en el directorio elegido
if command -v yazi >/dev/null 2>&1; then
  function y() {
    local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    local cwd; cwd="$(command cat -- "$tmp")"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi

# ----------------------------------------------------------------------------
# Herramientas: inicializar solo si estan instaladas (resiliente y portable)
# ----------------------------------------------------------------------------
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v mise     >/dev/null 2>&1 && eval "$(mise activate zsh)"
