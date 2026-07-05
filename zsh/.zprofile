# Homebrew (solo macOS, si esta instalado) — guard para no romper en Linux
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"

# ~/.local/bin en PATH (herramientas user-local)
export PATH="$HOME/.local/bin:$PATH"
