# nvim
Just my personal nvim settings.

## Getting started
Put this under `~/.config/nvim`, then open nvim and run `:Lazy sync`. Mason will auto-install all LSP servers.

### External tools
- (optional) [delta](https://github.com/dandavison/delta) for nicer git-diff — adapt git config to use it in nvim

---

## Plugins

| Plugin | Purpose |
|--------|---------|
| lazy.nvim | Plugin manager |
| tokyonight.nvim | Colorscheme |
| lualine.nvim | Statusline + tabline |
| telescope.nvim | Fuzzy finder |
| nvim-tree.lua | File explorer |
| nvim-treesitter | Syntax highlighting |
| nvim-lspconfig | LSP client |
| mason.nvim | LSP / tool installer |
| conform.nvim | Formatter |

## LSP

Auto-installed via Mason on first start.

| Language | Server |
|----------|--------|
| Rust | rust_analyzer (clippy, all features) |
| C / C++ | clangd |
| C# | omnisharp |
| Python | pyright |

---

## Keymaps

### File search (`<leader>f`)

| Key | Action |
|-----|--------|
| `<leader>h`  | Show all custom keymaps |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fe` | Live grep filtered by extension — prompts e.g. `c cs json` |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Registers |
| `<leader>ft` | Toggle file tree |

### Code navigation (`<leader>c`)

| Key | Action |
|-----|--------|
| `<leader>cd` | Go to definition |
| `<leader>cu` | Usages / references |
| `<leader>ci` | Incoming calls (who calls this) |
| `<leader>co` | Outgoing calls (what this calls) |
| `<leader>cj` | Jump list |
| `<leader>cc` | `cargo check` (save first) |
| `<leader>cr` | `cargo run` (save first) |

### Git (`<leader>g`)

| Key | Action |
|-----|--------|
| `<leader>gc` | Git commits |
| `<leader>gf` | Git commits for current buffer |
| `<leader>gb` | Git branches |
| `<leader>gs` | Git status |
| `<leader>gd` | Git diff to commit (custom extension) |

### Telescope (inside picker)

| Key | Action |
|-----|--------|
| `<C-j>` / `<C-k>` | Move selection down / up |
| `<Up>` / `<Down>` | Scroll preview |
| `<Left>` / `<Right>` | Scroll preview horizontally |
| `<C-t>` | Open in new tab (supports multi-select with `<Tab>`) |
| `<C-h>` | Show which-key help |

### File tree (nvim-tree)

| Key | Action |
|-----|--------|
| `<Space>` | Preview file |
| `<Up>` / `<Down>` | Scroll preview content |
| `h` | Go to parent directory |
| `l` | Change root to current node |
| `t` | Open in new background tab (stays in tree) |
| `v` | Open in vertical split |
| `x` | Open in horizontal split |
| `q` / `<ESC>` | Close tree |
| `?` | Help |

---

## Project-local keymaps

Copy `example/.nvim.lua` to the root of any project to define project-specific shortcuts on `<leader>1` – `<leader>9`.

```sh
cp ~/.config/nvim/example/.nvim.lua /your/project/.nvim.lua
```

On first `nvim .` inside that project, Neovim will prompt to trust the file. Confirm once — it auto-loads silently on every subsequent open.

Edit the file to map whatever commands make sense for that project. The example ships with `<leader>1` / `<leader>2` / `<leader>3` mapped to `cargo check` / `cargo run` / `cargo test` as a starting point.
