# dotfiles

> Dotfiles personales, públicos como referencia. Copia lo que te sirva —
> especialmente [`bootstrap.sh`](./bootstrap.sh) (instalador idempotente y
> multiplataforma). Es mi config personal, sin garantías: úsala bajo tu propio
> criterio. Los temas y keymaps son cuestión de gusto; el valor reutilizable
> está en el instalador y la estructura con Stow.

Configuración de mi entorno de desarrollo, **multiplataforma** (macOS · Fedora ·
Ubuntu), gestionada con [GNU Stow](https://www.gnu.org/software/stow/) (symlinks).
El instalador [`bootstrap.sh`](./bootstrap.sh) **detecta el SO/distro** y usa el
método correcto en cada uno:

| Plataforma | Apps | Fuentes |
|---|---|---|
| **macOS** | Homebrew ([`Brewfile`](./Brewfile)) | sí (cask) |
| **Fedora** (desktop) | `dnf` + instaladores oficiales → `~/.local/bin` | sí (Nerd Fonts locales) |
| **Ubuntu** (server/SSH) | `apt` + instaladores oficiales → `~/.local/bin` | **no** (las pone tu terminal cliente) |

El objetivo: en una máquina nueva, **recuperar el entorno idéntico con tres comandos**.

> 📖 **¿Cómo se usan las herramientas?** Guía práctica en [`HOWTO.md`](./HOWTO.md)
> (nvim, yazi, nushell, mise, gh, lazygit, etc.).

> **Sobre SSH y fuentes:** al entrar por SSH desde tu Mac, los iconos de Neovim y
> starship los **renderiza el terminal de tu Mac** (que ya tiene la Nerd Font), no
> el servidor. Por eso los servidores headless no necesitan instalar fuentes.

---

## 📦 Qué incluye

### Apps (vía Homebrew — ver [`Brewfile`](./Brewfile))

`antidote` · `eza` · `fastfetch` · `fd` · `ffmpeg` · `fzf` · `gh` · `git` ·
`imagemagick` · `jq` · `lazygit` · `mise` · `neovim` · `nushell` · `poppler` ·
`sevenzip` · `starship` · `stow` · `tmux` · `tree` · `uv` · `yazi` · `zoxide`
\+ las **Nerd Fonts** (JetBrainsMono, FiraCode, GeistMono).
(ffmpeg/imagemagick/poppler/sevenzip/jq son dependencias de preview de **yazi**.)

### Configuraciones (paquetes de stow)

| Paquete | Se enlaza a | Contenido |
|---|---|---|
| `nvim` | `~/.config/nvim` | Neovim configurado como IDE (LazyVim) |
| `starship` | `~/.config/starship.toml` | Prompt |
| `mise` | `~/.config/mise` | Versiones de runtimes |
| `git` | `~/.gitconfig` | Config de git |
| `zsh` | `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.zsh_plugins.txt` | Shell + lista de plugins (antidote) |
| `nushell` | `~/Library/Application Support/nushell` | `config.nu`, `env.nu` |
| `yazi` | `~/.config/yazi` | Explorador de archivos + flavor Tokyo Night |

### Qué NO está aquí (a propósito)

Secretos y datos locales: `~/.ssh`, `~/.config/gh` (token de GitHub),
credenciales de apps, cachés. **Nunca** los subas a este repo.

---

## 🔗 ¿Qué es un symlink y cómo funciona?

Un **symlink** (enlace simbólico) es un archivo especial que **apunta a otro
archivo**. Cuando una app abre o edita el symlink, en realidad está abriendo o
editando el archivo al que apunta — es transparente.

Este repo se basa en esa idea: el archivo de configuración real vive **una sola vez**
dentro de `~/dotfiles/…` (versionado en git), y [`stow`](https://www.gnu.org/software/stow/)
crea un symlink en la ruta donde cada app espera encontrarlo (`~/.zshrc`,
`~/.config/nvim`, …).

```
  ~/.zshrc            ──►   ~/dotfiles/zsh/.zshrc
  (symlink, lo que                (archivo REAL,
   ve la shell)                    versionado en git)
```

**Consecuencias prácticas (importante entenderlas):**

- Editas `~/.zshrc` como siempre, pero el cambio ocurre **dentro del repo** → un solo
  origen de verdad. Por eso `git add`/`commit` se hacen en `~/dotfiles`, no en `$HOME`.
- En otra máquina, `git pull` + `stow` deja exactamente la misma config.
- Borrar el symlink **no borra** el archivo real del repo (por eso `stow -D` es seguro).

**Cómo inspeccionar un symlink:**

```bash
ls -l ~/.zshrc        # → .zshrc -> dotfiles/zsh/.zshrc   (la flecha indica symlink)
readlink -f ~/.zshrc  # → /Users/tu-usuario/dotfiles/zsh/.zshrc  (ruta real)
```

---

## 🚀 Recuperar el entorno en una Mac nueva

### Paso 1 — Clonar el repo

> Necesitas git (viene con las Xcode Command Line Tools). Si no lo tienes, al
> ejecutar `git` macOS te ofrecerá instalarlas, o corre `xcode-select --install`.

```bash
git clone git@github.com:aikssen/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Si aún no tienes tu llave SSH en la máquina nueva, usa HTTPS:

```bash
git clone https://github.com/aikssen/dotfiles.git ~/dotfiles
```

### Paso 2 — Ejecutar el bootstrap

```bash
./bootstrap.sh
```

El script es **idempotente** (puedes correrlo varias veces sin romper nada) y hace:

1. Instala las **Xcode Command Line Tools** si faltan.
2. Instala **Homebrew** si falta.
3. `brew bundle` → instala todas las apps y las **Nerd Fonts** del `Brewfile`.
4. Respalda cualquier dotfile real en conflicto a `*.bak.<fecha>`.
5. **Enlaza** todas las configuraciones con `stow`.
6. Pre-instala los plugins de **Neovim** (`:Lazy sync` en modo headless).

### Paso 3 — Configurar la fuente del terminal (manual) 🔤

> **Importante:** este paso es manual. Homebrew instala las fuentes, pero hay que
> **seleccionarlas en el terminal** a mano. Sin una Nerd Font, los iconos de
> Neovim (neo-tree, lualine) y de starship se ven como cuadritos `□`.

Las fuentes instaladas por el `Brewfile` son:

- **JetBrainsMono Nerd Font** (recomendada)
- FiraCode Nerd Font
- GeistMono Nerd Font

Selecciónala en tu terminal:

- **WaveTerm:** Settings → Terminal → *Font* → `JetBrainsMono Nerd Font`.
- **iTerm2:** Settings → Profiles → Text → *Font* → `JetBrainsMono Nerd Font`.
- **Terminal.app:** Settings → Profiles → Text → *Change…* → `JetBrainsMono Nerd Font`.
- **Ghostty:** en `~/.config/ghostty/config` → `font-family = JetBrainsMono Nerd Font`.

### Paso 4 — Reiniciar la shell

```bash
exec zsh
```

---

## 🐧 Linux (Fedora y Ubuntu)

El mismo flujo funciona en Linux — `bootstrap.sh` detecta la distro automáticamente:

```bash
git clone https://github.com/aikssen/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

Qué hace en Linux:

1. **Paquetes del sistema** (`dnf` en Fedora, `apt` en Ubuntu, requiere sudo):
   `git curl ripgrep fzf stow tree tmux fd-find eza zsh gcc make unzip`. Además fija
   **zsh como shell por defecto** (`chsh`, efectivo al re-loguear).
2. **Neovim**: tarball oficial → `~/.local/bin/nvim` (misma versión que el Mac;
   el de `apt` suele ser demasiado viejo para LazyVim).
3. **Instaladores oficiales user-local** (sin sudo, → `~/.local/bin`):
   `starship`, `zoxide`, `mise`, `uv`.
4. **Binarios de GitHub releases**: `lazygit`, `nushell`.
5. En Ubuntu, donde `fd` se llama `fdfind`, crea el symlink `~/.local/bin/fd`.
6. **Runtimes con mise** (`node`, `go`, `python`, `rust`, `pnpm`) — node es necesario
   para los LSP de Neovim (Mason).
7. **Fuentes**: solo en perfil *desktop* (Fedora). En servidores se omiten.

### Perfil desktop vs server

Se autodetecta: **desktop** en macOS y Fedora; **server** en Ubuntu/Debian. La única
diferencia es si se instalan las Nerd Fonts localmente. Para forzarlo:

```bash
DOTFILES_PROFILE=desktop ./bootstrap.sh   # instala fuentes
DOTFILES_PROFILE=server  ./bootstrap.sh   # sin fuentes
```

### Notas por plataforma

- **Fedora**: tras correr el script, selecciona `JetBrainsMono Nerd Font` en el
  terminal del escritorio (GNOME Terminal/Ptyxis: Preferences → Text → Custom font).
- **Ubuntu server (SSH)**: no hay nada que configurar en el servidor para las
  fuentes; basta con que el terminal de tu Mac use una Nerd Font.
- **nushell** en Linux vive en `~/.config/nushell` (en macOS, en
  `~/Library/Application Support/nushell`); `bootstrap.sh` elige el destino correcto.
- Tras instalar, `~/.local/bin` debe estar en el `PATH` (ya lo gestiona `zsh/.zshrc`
  y `zsh/.zprofile`).

---

## 🖥️ Shell (zsh)

Setup rápido y vistoso, **sin oh-my-zsh** (arranca en ~50–60 ms):

- **Prompt: [starship](https://starship.rs)** (`starship/.config/starship.toml`) →
  icono del SO, ruta corta, rama+estado de git, lenguaje y versión (node, python, go,
  rust…), y `usuario@host` solo en sesiones SSH. Paleta *nord*.
- **`ls` con iconos: [eza](https://eza.rocks)** → `ls`, `ll`, `la`, `lt` (árbol).
- **Plugins vía [antidote](https://antidote.sh)** (lista en `zsh/.zsh_plugins.txt`):
  autosuggestions, fast-syntax-highlighting, completions, history-substring-search.

### ⚠️ Warp: dos cosas importantes

Si usas **Warp** (la terminal del Mac):

1. **Activa el prompt de starship** (si no, Warp muestra el suyo y starship queda
   invisible): *Settings → Appearance → **Honor user's custom prompt (PS1)*** (actívalo).
2. Los plugins (autosuggestions/highlighting) **se cargan solo fuera de Warp**, porque
   Warp ya trae los suyos nativos y los plugins ZLE chocarían. El `.zshrc` lo detecta
   con `if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]`. En tus **servidores Linux por SSH**
   sí se cargan (ahí el editor de línea es el de zsh).

### Cambiar el tema/paleta del prompt

En `starship/.config/starship.toml`, edita la línea `palette = 'tokyonight'` (hay también
paletas `nord` y `onedark` definidas), o ajusta los colores en `[palettes.tokyonight]`.

---

## 📂 Explorador de archivos (Yazi)

[Yazi](https://yazi-rs.github.io) es un file manager de terminal (Rust, rápido, con
previews). Config en `yazi/.config/yazi/` con el **flavor Tokyo Night** *vendorizado* en
`flavors/tokyo-night.yazi/` (incluido en el repo → sin descargas en setup).

- **Abrir:** `y` (wrapper en `.zshrc`) — al salir con `q`, la shell queda en el
  directorio donde estabas navegando. También `yazi` directo (sin cambiar de dir).
- **Previews:** texto, PDF (poppler), JSON (jq), archivos comprimidos (7zip), metadata de
  video (ffmpeg) e imágenes (imagemagick). Todas las dependencias las instala el
  `Brewfile`/`bootstrap.sh`.
- **⚠️ Imágenes en Warp:** Warp no renderiza imágenes inline (no soporta sixel/kitty), así
  que las previews de **imagen** no se ven en Warp (sí el resto). Funcionan completas en
  Fedora, Ghostty, iTerm2 o kitty.
- **Tema:** para cambiarlo, edita `yazi/.config/yazi/theme.toml` (`dark = "..."`) y añade
  el flavor en `flavors/`.

---

## 💾 Guardar / actualizar cambios

Como las configuraciones son **symlinks al repo**, cualquier cambio que hagas
(editar tu config de nvim, tu `.zshrc`, etc.) modifica directamente los archivos
de `~/dotfiles`. Para respaldarlos y poder recuperarlos en otra máquina, haz commit
y push **cada vez que cambies algo**:

```bash
cd ~/dotfiles
git add -A
git commit -m "Describe el cambio (ej: nvim: añadir plugin X)"
git push
```

Atajo opcional — añade este alias a `zsh/.zshrc`:

```bash
alias dotsave='cd ~/dotfiles && git add -A && git commit -m "update dotfiles" && git push && cd -'
```

Así, tras cualquier ajuste, basta con `dotsave`.

### Traer los últimos cambios a otra máquina

En la otra Mac (ya configurada con este repo):

```bash
cd ~/dotfiles
git pull
# Si añadiste paquetes o apps nuevas:
brew bundle --file=~/dotfiles/Brewfile   # instala apps nuevas
stow -t "$HOME" nvim starship mise git zsh   # re-enlaza por si hay archivos nuevos
```

> `stow` es seguro de re-ejecutar: solo crea los symlinks que falten.

---

## 🛠️ Mantenimiento

### ➕ Añadir una nueva app CLI a toda la configuración (paso a paso)

Ejemplo completo: agregar **`aws-cli`** y versionar su configuración. Hay dos partes
independientes: **(A)** que la app se instale en cada máquina, y **(B)** que su config
se respalde en el repo. Puedes hacer una, la otra, o ambas.

> ⚠️ **Ojo con los secretos.** `aws-cli` es un buen ejemplo justo porque su carpeta
> `~/.aws/` tiene **dos** archivos: `config` (región, perfiles — **NO secreto**) y
> `credentials` (tus *access keys* — **SECRETO**). Versionaremos solo `config`.

#### Parte A — Instalar la app en todas las plataformas

El repo tiene 3 mecanismos de instalación; añade la app al que corresponda:

1. **macOS** → edita el [`Brewfile`](./Brewfile) y añade una línea:
   ```ruby
   brew "awscli"
   ```
   Luego instálala: `brew bundle --file=~/dotfiles/Brewfile`

2. **Linux** → edita [`bootstrap.sh`](./bootstrap.sh):
   - **Si está en los repos** de la distro: añade el nombre a la línea `pkg_install …`
     dentro de `bootstrap_linux()` (en Fedora el paquete es `awscli2`):
     ```bash
     pkg_install git curl tar gzip unzip ripgrep fzf stow tree tmux fd-find gcc make awscli2
     ```
   - **Si NO está en repos o quieres la última versión** (caso típico de aws-cli v2):
     añade un instalador *user-local* siguiendo el patrón de los helpers que ya
     existen (`install_lazygit_linux`, `install_via_script`) que descargan a
     `~/.local/bin` sin `sudo`. Por ejemplo, una función nueva:
     ```bash
     install_awscli_linux() {
       command -v aws >/dev/null 2>&1 && return 0
       local tmp; tmp="$(mktemp -d)"
       curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "$tmp/aws.zip"
       unzip -q "$tmp/aws.zip" -d "$tmp"
       "$tmp/aws/install" --install-dir "$HOME/.local/aws-cli" --bin-dir "$HOME/.local/bin"
       rm -rf "$tmp"
     }
     ```
     y llámala dentro de `bootstrap_linux()`.

3. **Verifica**: `aws --version`

#### Parte B — Guardar su configuración en dotfiles

1. **Localiza** dónde guarda su config la app. aws-cli usa `~/.aws/` →
   `config` (versionable) y `credentials` (secreto, NO versionar).

2. **Crea el paquete de stow** espejando la ruta relativa a `$HOME` y mueve **solo**
   el archivo no secreto:
   ```bash
   mkdir -p ~/dotfiles/aws/.aws
   mv ~/.aws/config ~/dotfiles/aws/.aws/config    # SOLO config — NO credentials
   ```

3. **Protege los secretos**: añade a [`.gitignore`](./.gitignore):
   ```
   aws/.aws/credentials
   ```
   Deja `~/.aws/credentials` donde está (sin mover): no se versiona y aws-cli lo
   seguirá leyendo desde su sitio real.

4. **Enlaza con stow** (recrea `~/.aws/config` como symlink al repo):
   ```bash
   cd ~/dotfiles
   stow -t "$HOME" aws
   ```
   Comprueba: `ls -l ~/.aws/config` → debe apuntar a `…/dotfiles/aws/.aws/config`.

5. **Guarda y sube**:
   ```bash
   git add -A
   git commit -m "aws: versionar config (sin credentials)"
   git push
   ```
   (o simplemente `dotsave`).

#### Parte C — Aplicarlo en otra máquina

```bash
cd ~/dotfiles && git pull
# Instalar la app (Parte A):
brew bundle --file=~/dotfiles/Brewfile     # macOS
# ./bootstrap.sh                           # Linux (instala lo nuevo)
# Enlazar su config (Parte B):
stow -t "$HOME" aws
```

> El mismo patrón sirve para cualquier app: **A)** añádela al instalador de cada SO,
> **B)** crea `~/dotfiles/<app>/<ruta-relativa-a-$HOME>` con sus archivos no secretos,
> `stow -t "$HOME" <app>`, y commit. Para configs bajo `~/.config/foo/` el paquete
> sería `~/dotfiles/foo/.config/foo/…`.

### Quitar los symlinks de un paquete

```bash
cd ~/dotfiles
stow -D nvim      # elimina los symlinks de 'nvim' (no borra el repo)
```

---

## ⚠️ Solución de problemas

- **`stow: WARNING! conflicts ...`** — ya existe un archivo real en el destino.
  Muévelo (`mv ~/.zshrc ~/.zshrc.bak`) y reintenta el `stow`. `bootstrap.sh` ya
  hace este respaldo automáticamente.
- **Iconos como `□` en Neovim** — falta seleccionar la Nerd Font en el terminal
  (ver Paso 3).
- **Error al abrir la shell sobre `~/.cargo/env`** — Rust no está instalado;
  `zsh/.zshenv` ya lo contempla con un guard (`[ -f ... ] && …`). Instala Rust con
  `rustup` si lo necesitas.
- **nushell no toma la config** — vive en `~/Library/Application Support/nushell`;
  re-enlaza con `stow -t "$HOME/Library/Application Support" nushell`.

---

## 📁 Estructura

```
~/dotfiles/
├── Brewfile          # apps CLI + Nerd Fonts
├── bootstrap.sh      # instalador idempotente para una Mac nueva
├── README.md
├── .gitignore
├── nvim/      .config/nvim/…
├── starship/  .config/starship.toml
├── mise/      .config/mise/config.toml
├── git/       .gitconfig
├── zsh/       .zshrc .zprofile .zshenv .zsh_plugins.txt
├── nushell/   nushell/{config.nu,env.nu}
└── yazi/      .config/yazi/{yazi.toml,theme.toml,flavors/}
```
