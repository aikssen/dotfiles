# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repo

Dotfiles personales **multiplataforma** (macOS · Fedora · Ubuntu) gestionados con
**GNU Stow**. No es código de aplicación: son archivos de configuración + un
instalador. El objetivo es que en cualquier máquina nueva, `git clone` + `./bootstrap.sh`
deje el entorno idéntico.

El `README.md` es la doc para el usuario final; este archivo es la guía de arquitectura
para editar el repo con seguridad.

## Dos conceptos que mandan en todo el repo

1. **Stow = symlinks.** Cada carpeta de primer nivel (`nvim/`, `zsh/`, `git/`, etc.) es
   un *paquete* de stow que **espeja la ruta relativa a `$HOME`**. Ej.: el archivo real
   `zsh/.zshrc` se enlaza a `~/.zshrc`; `nvim/.config/nvim/` → `~/.config/nvim/`. Editar
   `~/.zshrc` edita el archivo del repo (es un symlink). Por eso `git add`/`commit` se
   hacen en `~/dotfiles`, nunca en `$HOME`.

2. **Instalar la app y versionar su config son cosas SEPARADAS.** Una app puede estar en
   `bootstrap.sh`/`Brewfile` sin tener config versionada, y viceversa. Al agregar una
   herramienta, decide cuál de las dos (o ambas) aplica.

## Cómo agregar una nueva herramienta CLI (lo más importante)

Sigue estas dos partes según corresponda. Hay un ejemplo paso a paso completo
(`aws-cli`) en `README.md` → sección "Añadir una nueva app CLI".

### Parte A — Instalación (que la app exista en cada SO)

El repo tiene **3 mecanismos**; agrega la app al que corresponda:

- **macOS** → añade una línea al `Brewfile` (`brew "x"` o `cask "x"`). Mantén el orden
  alfabético de las líneas `brew`.
- **Linux, si está en repos** → añade el nombre del paquete a la línea `pkg_install …`
  dentro de `bootstrap_linux()` en `bootstrap.sh`. Atención a nombres por distro
  (ej. `fd-find` en vez de `fd`; en Ubuntu el binario es `fdfind` → ver `ensure_fd()`).
- **Linux, si NO está en repos o quieres la última versión** → escribe una función
  `install_<tool>_linux()` que descargue a `~/.local/bin` **sin sudo**, siguiendo los
  patrones existentes, y llámala dentro de `bootstrap_linux()`:
  - script oficial → mira `install_via_script()` (starship/zoxide/mise/uv).
  - binario de GitHub releases → usa el helper `gh_latest_tag owner/repo` y mira
    `install_lazygit_linux()` / `install_nushell_linux()` / `install_eza_linux()`.

Convenciones de `bootstrap.sh` (todas ya existen, **reúsalas**):
- `log` / `warn` para mensajes; instaladores best-effort terminan en `|| warn`.
- `command -v <tool> >/dev/null 2>&1 && return 0` al inicio para idempotencia.
- Arch ya resuelta en variables `NVIM_ARCH` / `LG_ARCH` / `NU_ARCH` (x86_64|arm64|aarch64).
- `~/.local/bin` ya se crea al inicio y está en `PATH`.
- El script corre con `set -euo pipefail`: cualquier comando que pueda fallar de forma
  no crítica debe tolerarse (`|| warn`, `|| true`).

### Parte B — Versionar su configuración

1. Localiza dónde guarda su config (`~/.config/<app>/…`, `~/.<app>rc`, etc.).
2. Crea el paquete espejando la ruta relativa a `$HOME` y **mueve** los archivos
   no secretos al repo:
   ```bash
   mkdir -p ~/dotfiles/<app>/.config && mv ~/.config/<app> ~/dotfiles/<app>/.config/<app>
   ```
3. Si la app guarda config en una ruta distinta por SO (caso **nushell**:
   `~/Library/Application Support` en macOS vs `~/.config` en Linux), maneja el
   `nu_target` en `link_dotfiles()`; no asumas `$HOME` plano.
4. Enlaza: `stow -t "$HOME" <app>` (o `stow -R` para re-enlazar tras añadir archivos a
   un paquete existente).
5. Si la app tiene **secretos** junto a la config (claves, tokens), versiona solo lo no
   secreto y añade el archivo sensible a `.gitignore`. Nunca se versionan: `~/.ssh`,
   `~/.config/gh`, credenciales.

Tras cualquier cambio: `git add -A && git commit && git push` (alias `dotsave`).

## Estructura de `bootstrap.sh`

Flujo: detecta plataforma (`uname` + `/etc/os-release`) y **perfil** (`desktop` en
macOS/Fedora, `server` en Ubuntu/Debian; override con `DOTFILES_PROFILE`). Luego:
`bootstrap_macos` **o** `bootstrap_linux` → `link_dotfiles` → `post_install`.

- `link_dotfiles()`: respalda conflictos (`backup_stow_pkg` revisa TODOS los archivos de
  cada paquete, no una lista fija) y hace `stow -t "$HOME" nvim starship mise git zsh` +
  nushell con su target especial. **Si agregas un paquete nuevo, añádelo a esta lista.**
- `post_install()`: `mise install` (runtimes; node es necesario para los LSP de Neovim) y
  `nvim --headless "+Lazy! sync" +qa`.

## Cosas que romperás si no las respetas

- **Portabilidad de los shell configs.** `zsh/.zshrc`, `.zprofile`, `.zshenv` deben
  funcionar en macOS **y** Linux. Todo lo específico de un SO va con guard:
  `[ -x /opt/homebrew/bin/brew ] && eval …`, `[ -d <path> ] && export PATH=…`,
  `command -v <tool> >/dev/null 2>&1 && eval …`. No añadas rutas absolutas sin guard.
- **`~/.local/bin` antes de los `eval` de tools** en `.zshrc` (si no, no se encuentran
  los binarios user-local en Linux).
- **Warp.** `zsh/.zshrc` carga los plugins (antidote) **solo si**
  `[[ "$TERM_PROGRAM" != "WarpTerminal" ]]`, porque Warp trae autosuggestions/
  syntax-highlighting nativos y los plugins ZLE chocan. Mantén ese gate. Los plugins
  se declaran en `zsh/.zsh_plugins.txt` (formato antidote: `owner/repo` por línea).
- **starship** (`starship/.config/starship.toml`): los módulos referencian nombres de
  color de la paleta activa (`palette = 'tokyonight'`). Si usas un color nuevo, defínelo
  en `[palettes.tokyonight]`, o romperás el render. Hay `nord`/`onedark` también definidas.

## Verificación tras editar

- `bash -n bootstrap.sh` y `zsh -n zsh/.zshrc` (sintaxis).
- `brew bundle check --file=Brewfile` (deps macOS satisfechas).
- `STARSHIP_CONFIG=starship/.config/starship.toml starship prompt` (render sin errores).
- Arranque: `for i in 1 2 3; do /usr/bin/time -p zsh -i -c exit; done` (debe seguir
  ~rápido; en Warp ~60ms).
- La prueba real de `bootstrap.sh` en Linux se hace en una VM/host limpio (las VMs
  recién instaladas son el mejor banco de pruebas para los edge cases del instalador).
