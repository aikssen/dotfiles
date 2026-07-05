# HOWTO — uso diario de las herramientas

Guía práctica de **cómo usar** las herramientas de este entorno. (Para *instalar/
reproducir* el setup, mira [`README.md`](./README.md).)

**Convenciones:**
- En Neovim el *leader* es la **barra espaciadora** (`Espacio`).
- En las apps de terminal (TUI): `q` sale, `?` o `~` suele mostrar la ayuda.
- `C-x` = `Ctrl+x`; `S-x` = `Shift+x`.

---

# 🚀 Herramientas principales

## Neovim (`nvim`) — editor / IDE (LazyVim)

Editor modal. Trabajas cambiando de **modo**:
- **Normal** (al abrir): navegar y ejecutar comandos. `Esc` vuelve aquí siempre.
- **Insertar**: escribir texto. Se entra con `i` (antes del cursor), `a` (después), `o` (línea nueva).
- **Visual**: seleccionar. `v` (carácter), `V` (línea), `C-v` (bloque).
- **Comando**: `:` abre la línea de comandos (`:w` guardar, `:q` salir, `:wq` ambas, `:q!` salir sin guardar).

Movimiento básico (modo normal): `h j k l` (←↓↑→), `w`/`b` palabra adelante/atrás,
`gg`/`G` inicio/fin del archivo, `0`/`$` inicio/fin de línea, `/texto` buscar.

Atajos del IDE (LazyVim, leader = `Espacio`):

| Acción | Atajo |
|---|---|
| Explorador de archivos | `Espacio e` |
| Buscar archivos | `Espacio ff` |
| Buscar texto en el proyecto (grep) | `Espacio sg` |
| Ir a definición / hover docs | `gd` / `K` |
| Renombrar símbolo / code action | `Espacio cr` / `Espacio ca` |
| Diagnósticos siguiente/anterior | `]d` / `[d` |
| Cambiar de buffer (pestaña) | `S-h` / `S-l` |
| Git (abre lazygit) | `Espacio gg` |
| Terminal flotante | `Ctrl-/` |
| Comentar línea/selección | `gcc` / `gc` |
| Gestor de plugins / LSP | `:Lazy` / `:Mason` |

**Flujo típico:** `nvim .` en la raíz del proyecto → `Espacio e` para ver el árbol →
`Espacio ff` para saltar a un archivo → editar → `gd`/`K` para navegar el código →
`Espacio gg` para commitear → `:wq`.

**Añadir un plugin:** crea un archivo en `nvim/.config/nvim/lua/plugins/` que retorne la
spec del plugin; reinicia nvim y se instala solo. Lenguajes nuevos: `:LazyExtras`.

## Yazi (`y`) — explorador de archivos

Se abre con **`y`** (al salir con `q`, tu shell queda en el directorio donde estabas) o
con `yazi` (no cambia de directorio al salir).

| Acción | Tecla |
|---|---|
| Moverse | `h` (subir nivel) `j`/`k` (abajo/arriba) `l` (entrar) |
| Arriba/abajo del todo | `g g` / `G` |
| Copiar / cortar / pegar | `y` / `x` / `p` |
| Borrar (a papelera) / borrar definitivo | `d` / `D` |
| Crear archivo/carpeta (termina en `/`) | `a` |
| Renombrar | `r` |
| Seleccionar (marca) / modo visual | `Espacio` / `v` |
| Buscar / filtrar | `s` (por nombre, fd) `/` (saltar) `f` (filtrar) |
| Pestañas | `t` (nueva) `1`…`9` (ir a) |
| Mostrar ocultos | `.` |
| Abrir con… / shell | `o` / `;` |
| Ayuda / salir | `~` / `q` |

**Previews:** texto, PDF, JSON, comprimidos y metadata de video se ven en el panel
derecho. ⚠️ Las **imágenes no se ven en Warp** (no soporta gráficos inline); sí en
Fedora/Ghostty/iTerm2/kitty.

**Flujo típico:** `y` → navegar con `h/j/k/l` → `Espacio` para marcar varios → `y` copiar
→ ir al destino → `p` pegar → `q` (la shell te deja ahí).

## Nushell (`nu`) — shell de datos estructurados

Shell alterna donde **todo son tablas/datos**, no texto plano. No es tu shell de login
(esa es zsh); entras cuando la necesitas con `nu` y sales con `exit`.

```nu
ls | where size > 1mb            # filtra la tabla de archivos por tamaño
ls | sort-by modified | last 5   # los 5 más recientes
ps | where cpu > 10              # procesos por CPU
open datos.json | get usuarios   # parsea JSON y accede a un campo
open notas.csv | where edad > 30 # parsea CSV y filtra
sys | get host                   # info del sistema como datos
```

Lo potente: los `|` pasan **datos** (no texto), así que `where`, `get`, `sort-by`,
`select`, `each` operan sobre columnas. Útil para explorar JSON/CSV/logs.

## mise — gestor de versiones (runtimes)

Instala y cambia versiones de lenguajes por proyecto o global. Tu config global
(`mise/.config/mise/config.toml`) ya fija: `go 1.26`, `node 26`, `pnpm latest`,
`python 3.13`, `rust latest`.

```bash
mise ls                 # qué runtimes/versiones hay instalados
mise install            # instala todo lo declarado en la config
mise use -g node@22     # fija node 22 globalmente
mise use node@20        # fija node 20 SOLO en este proyecto (crea .mise.toml)
mise exec -- node -v    # corre un comando con el runtime gestionado
mise current            # versiones activas en el directorio actual
```

**Por proyecto:** dentro de la carpeta, `mise use python@3.12` crea un `.mise.toml`
local; al entrar al directorio, mise activa esa versión automáticamente.

## gh — GitHub desde la terminal

```bash
gh auth login                        # autenticarse (una vez por máquina)
gh repo clone aikssen/dotfiles       # clonar
gh repo create mi-repo --private     # crear repo
gh repo view --web                   # abrir el repo actual en el navegador

gh pr create                         # crear PR de la rama actual
gh pr list                           # listar PRs
gh pr checkout 42                    # traer el PR #42 a tu local
gh pr view 42 --web                  # ver el PR en el navegador

gh issue list                        # issues
gh gist create archivo.txt           # compartir un gist
```

## lazygit — Git visual (TUI)

Se abre con **`lazygit`** o desde Neovim con **`Espacio gg`**. Paneles a la izquierda
(Status, Files, Branches, Commits, Stash); se navega con `Tab` / flechas.

| Acción | Tecla |
|---|---|
| Cambiar de panel | `Tab` (o `1`…`5`) |
| Stage/unstage archivo | `Espacio` |
| Stage todo | `a` |
| Commit | `c` |
| Push / Pull | `P` / `p` |
| Ramas (en panel Branches): crear/cambiar | `n` / `Espacio` |
| Stash / aplicar stash | `s` / `Espacio` (en panel Stash) |
| Ver diff de un archivo | `Enter` |
| Ayuda (atajos del panel) / salir | `?` / `q` |

**Flujo típico:** `lazygit` → en *Files* marca cambios con `Espacio` (o `a` todo) →
`c` para commitear → escribe el mensaje → `P` para push.

## zoxide (`z`) — saltar a directorios

Recuerda los directorios que visitas y salta con un fragmento del nombre:

```bash
z dotfiles      # salta a ~/dotfiles aunque estés lejos
z conf nvim     # combina fragmentos
zi              # selector interactivo (fzf) entre tus dirs frecuentes
```

## eza — `ls` moderno (iconos + colores + git)

Ya está aliaseado:

| Alias | Hace |
|---|---|
| `ls` | listado con iconos, carpetas primero |
| `ll` | listado largo con tamaños, permisos y estado git |
| `la` | incluye ocultos |
| `lt` | árbol (2 niveles) |

---

# 🧰 Herramientas auxiliares (referencia rápida)

| Herramienta | Para qué | Ejemplo |
|---|---|---|
| **fd** | Buscar archivos (find moderno, rápido) | `fd factura` · `fd -e pdf` (por extensión) |
| **rg** (ripgrep) | Buscar **texto** dentro de archivos | `rg "TODO"` · `rg -i error logs/` |
| **fzf** | Selector fuzzy interactivo | `Ctrl-R` (historial) · `Ctrl-T` (archivos) · `vim $(fzf)` |
| **tree** | Ver estructura de carpetas | `tree -L 2` |
| **uv** | Paquetes/venv de Python (ultrarrápido) | `uv venv` · `uv pip install requests` · `uv run script.py` |
| **tmux** | Multiplexor (varias sesiones/paneles) | `tmux` · prefijo `Ctrl-b` luego `c` (ventana), `"`/`%` (split), `d` (detach) |
| **fastfetch** | Info del sistema (vistoso) | `fastfetch` |
| **starship** | El prompt (pasivo, no se invoca) | se ve solo al abrir la shell |

> `fzf` se potencia con `fd`/`rg` por debajo; `Ctrl-R` y `Ctrl-T` ya están activos en zsh.

---

# ⌨️ Tus aliases y atajos propios

| Comando | Qué hace |
|---|---|
| `ls` / `ll` / `la` / `lt` | eza (ver arriba) |
| `y` | abre Yazi y deja la shell en el dir donde saliste |
| `z <frag>` / `zi` | saltar a dir frecuente / elegirlo con fzf |
| `dotsave` | `git add -A && commit && push` en `~/dotfiles` (guarda tu config) |
| `git s` | `git status` |

---

# 🔗 Combos útiles

- **Editar lo que buscas:** `nvim $(fzf)` o, dentro de nvim, `Espacio ff` / `Espacio sg`.
- **Navegar + editar:** `z proyecto` para saltar, `y` para explorar, `nvim .` para editar.
- **Git rápido:** dentro de nvim `Espacio gg` abre lazygit sin salir del editor.
- **Saltar a un repo y ver su estado:** `z mirepo && lazygit`.
