#!/usr/bin/env bash
#
# bootstrap.sh — instala y enlaza este entorno (macOS / Fedora / Ubuntu).
# Idempotente: se puede reejecutar sin romper nada.
#
#   git clone <repo> ~/dotfiles && cd ~/dotfiles && ./bootstrap.sh
#
# Perfil (fuentes/GUI): se autodetecta (desktop en macOS y Fedora; server en
# Ubuntu/Debian). Forzar con:  DOTFILES_PROFILE=server ./bootstrap.sh
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
mkdir -p "$HOME/.local/bin"            # debe existir antes de cualquier symlink/instalador
export PATH="$HOME/.local/bin:$PATH"   # asegurar tools user-local en esta sesion

log()  { printf "\033[1;34m==>\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$1"; }

# ----------------------------------------------------------------------------
# Deteccion de plataforma
# ----------------------------------------------------------------------------
PLATFORM="$(uname -s)"   # Darwin | Linux
DISTRO=""
if [ "$PLATFORM" = "Linux" ] && [ -r /etc/os-release ]; then
  DISTRO="$(. /etc/os-release && echo "$ID")"   # fedora | ubuntu | debian | ...
fi

PROFILE="${DOTFILES_PROFILE:-}"
if [ -z "$PROFILE" ]; then
  case "$PLATFORM:$DISTRO" in
    Darwin:*|Linux:fedora) PROFILE="desktop" ;;
    *)                     PROFILE="server"  ;;
  esac
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  NVIM_ARCH="x86_64"; LG_ARCH="x86_64"; NU_ARCH="x86_64" ;;
  aarch64|arm64) NVIM_ARCH="arm64";  LG_ARCH="arm64";  NU_ARCH="aarch64" ;;
  *) warn "Arquitectura no reconocida: $ARCH (asumo x86_64)"; NVIM_ARCH="x86_64"; LG_ARCH="x86_64"; NU_ARCH="x86_64" ;;
esac

log "Plataforma: $PLATFORM ${DISTRO:+($DISTRO)} | arch: $ARCH | perfil: $PROFILE"

# ============================================================================
# macOS
# ============================================================================
bootstrap_macos() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Instalando Xcode Command Line Tools (acepta el dialogo y reejecuta)..."
    xcode-select --install || true
    warn "Cuando termine, vuelve a correr ./bootstrap.sh"; exit 1
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
  log "Instalando apps y fuentes (brew bundle)..."
  brew bundle --file="$DOTFILES/Brewfile"
}

# ============================================================================
# Linux — helpers
# ============================================================================
PKG=""
detect_pkg() {
  if command -v dnf >/dev/null 2>&1; then PKG="dnf"
  elif command -v apt-get >/dev/null 2>&1; then PKG="apt"
  else warn "No encontre dnf ni apt; instalare solo binarios user-local."; fi
}

pkg_install() {  # instala paquetes del sistema (best-effort, requiere sudo)
  [ -z "$PKG" ] && return 0
  case "$PKG" in
    dnf) sudo dnf install -y "$@" || warn "dnf: algun paquete fallo (continuo)";;
    apt) sudo apt-get update -y >/dev/null 2>&1 || true
         sudo apt-get install -y "$@" || warn "apt: algun paquete fallo (continuo)";;
  esac
}

gh_latest_tag() {  # owner/repo -> tag (ej v1.2.3 o 0.106.0)
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" \
    | sed -E 's#.*/tag/##'
}

ensure_fd() {  # en Ubuntu el binario es 'fdfind'; nvim/telescope busca 'fd'
  command -v fd >/dev/null 2>&1 && return 0
  if command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log "Enlazado fd -> fdfind"
  fi
}

install_neovim_linux() {  # tarball oficial -> misma version que el Mac, sin sudo
  if [ -x "$HOME/.local/nvim/bin/nvim" ]; then
    ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    log "Neovim ya instalado (omito descarga)."; return 0
  fi
  log "Instalando Neovim (tarball oficial)..."
  local dir="$HOME/.local/nvim"
  rm -rf "$dir"; mkdir -p "$dir"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
    | tar -xz -C "$dir" --strip-components=1
  ln -sf "$dir/bin/nvim" "$HOME/.local/bin/nvim"
}

install_lazygit_linux() {
  command -v lazygit >/dev/null 2>&1 && return 0
  log "Instalando lazygit..."
  local tag v; tag="$(gh_latest_tag jesseduffield/lazygit)"; v="${tag#v}"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${v}_Linux_${LG_ARCH}.tar.gz" \
    | tar -xz -C "$HOME/.local/bin" lazygit || warn "lazygit fallo"
}

install_nushell_linux() {
  command -v nu >/dev/null 2>&1 && return 0
  log "Instalando nushell..."
  local tag name tmp; tag="$(gh_latest_tag nushell/nushell)"
  name="nu-${tag}-${NU_ARCH}-unknown-linux-gnu"; tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/nushell/nushell/releases/download/${tag}/${name}.tar.gz" | tar -xz -C "$tmp"; then
    find "$tmp" -maxdepth 2 -type f -name 'nu*' -exec cp {} "$HOME/.local/bin/" \;
  else warn "nushell fallo"; fi
  rm -rf "$tmp"
}

install_gh_linux() {  # GitHub CLI (binario de GitHub release, sin sudo)
  command -v gh >/dev/null 2>&1 && return 0
  log "Instalando gh (GitHub CLI)..."
  local tag v gharch tmp; tag="$(gh_latest_tag cli/cli)"; v="${tag#v}"
  case "$ARCH" in
    x86_64|amd64)  gharch="amd64" ;;
    aarch64|arm64) gharch="arm64" ;;
    *) warn "gh: arquitectura no soportada ($ARCH)"; return 0 ;;
  esac
  tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/cli/cli/releases/download/${tag}/gh_${v}_linux_${gharch}.tar.gz" | tar -xz -C "$tmp"; then
    find "$tmp" -type f -path '*/bin/gh' -exec cp {} "$HOME/.local/bin/" \;
  else warn "gh fallo"; fi
  rm -rf "$tmp"
}

install_via_script() {  # tools rapidos: a ~/.local/bin, sin sudo
  command -v starship >/dev/null 2>&1 || { log "Instalando starship..."; curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" || warn "starship fallo"; }
  command -v zoxide   >/dev/null 2>&1 || { log "Instalando zoxide...";   curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || warn "zoxide fallo"; }
  command -v mise     >/dev/null 2>&1 || { log "Instalando mise...";     curl -fsSL https://mise.run | sh || warn "mise fallo"; }
  command -v uv       >/dev/null 2>&1 || { log "Instalando uv...";       curl -LsSf https://astral.sh/uv/install.sh | sh || warn "uv fallo"; }
}

install_eza_linux() {  # eza no siempre esta en repos viejos; fallback a GitHub
  command -v eza >/dev/null 2>&1 && return 0
  log "Instalando eza (GitHub release)..."
  local arch="$NU_ARCH"   # x86_64 | aarch64
  curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$HOME/.local/bin" ./eza 2>/dev/null || warn "eza fallo (instalalo manual)"
}

install_antidote_linux() {  # gestor de plugins de zsh (no esta en dnf/apt)
  [ -d "$HOME/.antidote" ] && { log "antidote ya presente."; return 0; }
  log "Instalando antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote" || warn "antidote fallo"
}

install_yazi_linux() {  # explorador de archivos (binario de GitHub, sin sudo)
  command -v yazi >/dev/null 2>&1 && return 0
  log "Instalando yazi..."
  local tag tmp; tag="$(gh_latest_tag sxyazi/yazi)"; tmp="$(mktemp -d)"
  if curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${tag}/yazi-${NU_ARCH}-unknown-linux-gnu.zip" -o "$tmp/yazi.zip"; then
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    find "$tmp" -type f \( -name yazi -o -name ya \) -exec cp {} "$HOME/.local/bin/" \;
  else warn "yazi fallo"; fi
  rm -rf "$tmp"
}

install_yazi_deps_linux() {  # dependencias de preview (nombres por distro)
  case "$PKG" in
    dnf) pkg_install ffmpeg poppler-utils jq p7zip p7zip-plugins ImageMagick ;;
    apt) pkg_install ffmpeg poppler-utils jq p7zip-full imagemagick ;;
  esac
}

ensure_zsh_default() {  # instala zsh (via pkg) y lo fija como shell por defecto
  local zsh_bin; zsh_bin="$(command -v zsh || true)"
  [ -z "$zsh_bin" ] && { warn "zsh no encontrado; no puedo fijarlo como shell."; return 0; }
  case "$SHELL" in *zsh) log "zsh ya es el shell por defecto."; return 0 ;; esac
  # /etc/shells debe listar zsh para que chsh lo acepte
  grep -qx "$zsh_bin" /etc/shells 2>/dev/null || echo "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
  log "Estableciendo zsh como shell por defecto (efectivo al re-loguear)..."
  sudo chsh -s "$zsh_bin" "$(whoami)" || warn "No pude cambiar el shell; hazlo con: chsh -s $zsh_bin"
}

install_nerd_fonts_linux() {  # solo perfil desktop
  log "Instalando Nerd Fonts (perfil desktop)..."
  local fdir="$HOME/.local/share/fonts"; mkdir -p "$fdir"
  local f
  for f in JetBrainsMono FiraCode; do
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${f}.zip" -o "/tmp/${f}.zip"; then
      unzip -oq "/tmp/${f}.zip" -d "$fdir/${f}NerdFont" && rm -f "/tmp/${f}.zip"
    fi
  done
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
}

bootstrap_linux() {
  detect_pkg
  log "Instalando paquetes del sistema..."
  # Nombres comunes en dnf y apt. fd-find provee 'fd' (Fedora) o 'fdfind' (Ubuntu).
  pkg_install git curl tar gzip unzip ripgrep fzf stow tree tmux fd-find eza zsh gcc make fastfetch
  ensure_fd
  install_eza_linux
  install_antidote_linux
  install_neovim_linux
  install_via_script
  install_lazygit_linux
  install_nushell_linux
  install_gh_linux
  install_yazi_linux
  install_yazi_deps_linux
  ensure_zsh_default
  [ "$PROFILE" = "desktop" ] && install_nerd_fonts_linux || log "Perfil server: omito fuentes (las provee el terminal cliente por SSH)."
}

# ============================================================================
# Enlazado de configuraciones (comun)
# ============================================================================
backup_if_real() {
  local target="$1"
  [ -e "$target" ] || return 0
  [ -L "$target" ] && return 0   # ya es un symlink: no es conflicto
  # CRITICO: si el target, resolviendo symlinks de directorio padre, ya apunta
  # DENTRO del repo, es nuestra propia config ya enlazada (stow plego el dir).
  # Hacer 'mv' aqui renombraria el archivo REAL del repo. No tocar.
  case "$(readlink -f "$target" 2>/dev/null)" in
    "$DOTFILES"/*) return 0 ;;
  esac
  warn "Respaldo: $target -> $target.bak.$STAMP"
  mv "$target" "$target.bak.$STAMP"
}

backup_stow_pkg() {  # respalda cualquier archivo real que el paquete fuese a pisar
  local pkg="$1" troot="$2" f rel
  while IFS= read -r f; do
    rel="${f#"$DOTFILES/$pkg/"}"
    backup_if_real "$troot/$rel"
  done < <(find "$DOTFILES/$pkg" -type f)
}

link_dotfiles() {
  log "Enlazando configuraciones con stow..."
  command -v stow >/dev/null 2>&1 || { warn "stow no esta instalado; no puedo enlazar."; return 1; }

  local pkg
  for pkg in nvim starship mise git zsh yazi; do backup_stow_pkg "$pkg" "$HOME"; done
  cd "$DOTFILES"
  stow -t "$HOME" nvim starship mise git zsh yazi

  # nushell vive en sitios distintos segun el SO
  local nu_target
  if [ "$PLATFORM" = "Darwin" ]; then nu_target="$HOME/Library/Application Support"; else nu_target="$HOME/.config"; fi
  mkdir -p "$nu_target"
  backup_stow_pkg nushell "$nu_target"
  stow -t "$nu_target" nushell
}

post_install() {
  # Runtimes con mise (node para los LSP de Mason, go, etc.)
  if command -v mise >/dev/null 2>&1; then
    log "Instalando runtimes con mise (node, go, pnpm)..."
    mise install -y || warn "mise install fallo (revisalo luego con 'mise install')"
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  # Plugins de Neovim
  if command -v nvim >/dev/null 2>&1; then
    log "Instalando plugins de Neovim (puede tardar)..."
    nvim --headless "+Lazy! sync" +qa || warn "Revisa los plugins con :Lazy"
  fi
}

# ============================================================================
# Main
# ============================================================================
case "$PLATFORM" in
  Darwin) bootstrap_macos ;;
  Linux)  bootstrap_linux ;;
  *) warn "Plataforma no soportada: $PLATFORM"; exit 1 ;;
esac

link_dotfiles
post_install

log "Listo."
echo
echo "  Siguientes pasos:"
echo "  1) Reinicia la shell:  exec zsh"
if [ "$PROFILE" = "desktop" ]; then
  echo "  2) Selecciona una Nerd Font en tu terminal (ej: 'JetBrainsMono Nerd Font')."
else
  echo "  2) (Server) Los iconos los renderiza tu terminal CLIENTE: asegurate de tener"
  echo "     una Nerd Font configurada en la Mac/PC desde donde haces SSH."
fi
echo
