# nnn-starter

<p align="center">
  <img src="screenshot.png" alt="Screenshot of the NNN desktop — Niri + Noctalia on NixOS" width="100%">
</p>

> Three letters, zero compromise — now with batteries included.

An opinionated [omarchy](https://omarchy.org)-style NixOS starter for the [**NNN
stack**](https://the-nnn-stack.github.io/): **N**ixOS + **N**iri + **N**octalia. Clone it, set two placeholders,
run one command, and get a cohesive, themed, developer-ready Wayland desktop.

## What you get

| Layer        | Choice |
|--------------|--------|
| Kernel       | CachyOS BORE + ThinLTO, `linux-cachyos-bore-lto-x86_64-v3` (requires an x86-64-v3 CPU) |
| Compositor   | [niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland) via [niri-flake](https://github.com/sodiboo/niri-flake) |
| Shell/UI     | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) **v5** (bar, launcher, notifications, lock, control center) |
| Theming      | [Stylix](https://github.com/nix-community/stylix) with the **Kanagawa** palette — one scheme themes everything |
| Terminal     | [Alacritty](https://alacritty.org/) |
| Shell + prompt | Fish + [Tide](https://github.com/IlanCosman/tide) (autosuggestions, syntax highlighting, fzf, zoxide) |
| Editor (GUI) | [Zed](https://zed.dev) — themed via Stylix; default handler for text/source files |
| Editor (AI)  | [Cursor](https://cursor.com) — VS Code-based; FHS wrap so extensions work on NixOS |
| Editor (terminal) | Neovim, preconfigured (LSP, treesitter, telescope, completion); the `$EDITOR` |
| Browser      | [Zen](https://zen-browser.app) (beta channel, via the community flake) |
| File manager | [Strata](https://github.com/lgse/strata) |
| Database IDE | DataGrip (JetBrains) |
| Office suite | LibreOffice |
| Notes        | [Obsidian](https://obsidian.md) — `Super+N` |
| Logitech     | [OpenLogi](https://github.com/AprilNEA/OpenLogi) — HID++ buttons, DPI, SmartShift; no account |
| Fonts        | JetBrains Mono Nerd Font (default monospace), Fira Code, Iosevka Nerd Font |
| Login        | greetd + tuigreet → niri session |

### Modern command-line toolset
`lsd` · `fzf` · `bat` · `btop` · `ripgrep` · `fd` · `zoxide` · `eza` · `yazi` ·
`dust` · `duf` · `procs` · `bandwhich` · `gping` · `zellij` ·
`tealdeer` · `jq` · `yq` · `lazygit` · `delta` · `gh` · `direnv` + `nix-direnv` ·
`nh` · `nom` · `claude` ([Claude Code](https://github.com/anthropics/claude-code)) ·
`codex` · `agy` ([Antigravity CLI](https://antigravity.google/product/antigravity-cli)) ·
`omp` ([oh-my-pi](https://github.com/can1357/oh-my-pi)).
Old names are aliased to the new tools (`ls`→`lsd`, `cat`→`bat`,
`cd`→`zoxide`, `top`→`btop`, …).

## Quick start

```sh
# 1. Get the repo onto your machine (or into the live NixOS installer).
git clone https://github.com/<you>/nnn-starter ~/nnn-starter
cd ~/nnn-starter

# 2. Generate real hardware config for THIS machine.
sudo nixos-generate-config --show-hardware-config > hosts/nnn/hardware-configuration.nix

# 3. Put your identity in local.nix (see Placeholders below), then keep your
#    edits out of git history:
git update-index --skip-worktree local.nix

# 4. Build & switch.
sudo nixos-rebuild switch --flake .#nnn
```

After the first build, rebuild with `nh os switch` (aliased to `rebuild`) or
`update` (which also bumps `flake.lock`).

For updates that change the kernel or NVIDIA driver, use `nh os boot --update`
and reboot. A live switch can start new NVIDIA userspace against the old
kernel module, causing `nvidia-persistenced` to fail with an API mismatch.

## Placeholders to edit

Your personal settings live in one place — [`local.nix`](local.nix). It's
tracked with neutral defaults but marked `skip-worktree` (step 3) so your real
values never get staged or committed.

| What | Where |
|------|-------|
| **Username, hostname, full name** | [`local.nix`](local.nix) |
| **Git identity** (name, email) | [`local.nix`](local.nix) |
| **Timezone** | [`local.nix`](local.nix) |
| **Monitor scale** | [`local.nix`](local.nix) |
| **Hardware** | `hosts/nnn/hardware-configuration.nix` (generated, step 2 above) |
| **Locale / keyboard layout** | [`hosts/nnn/default.nix`](hosts/nnn/default.nix) |
| **Monitor name / position** | `outputs` in [`modules/home/niri.nix`](modules/home/niri.nix) |

> Editing the defaults themselves (e.g. to change the placeholders this repo
> ships) needs `git update-index --no-skip-worktree local.nix` first.

## Layout

```
flake.nix              # inputs + `nixosConfigurations.nnn` (desktop) and `.rhea` (VPS)
local.nix              # your machine-local identity (skip-worktree)
hosts/nnn/             # host: hardware + locale/timezone
hosts/rhea/            # headless VPS: disko layout, SSH, nix gc
modules/nixos/         # system: boot, audio, niri, noctalia, stylix, users, OpenLogi…
modules/home/          # user: fish, alacritty, neovim, zed, cursor, niri keybinds, cli tools…
themes/kanagawa.yaml   # vendored base16 palette (Stylix source of truth)
```

## Key bindings (niri)

| Keys | Action |
|------|--------|
| `Mod`+`Return` | Terminal (Alacritty) |
| `Mod`+`Space` | Noctalia launcher |
| `Mod`+`B` | Browser (Zen) |
| `Mod`+`E` | File manager (Strata) |
| `Mod`+`Q` | Close window |
| `Mod`+`F` / `Mod`+`Shift`+`F` | Maximize column / fullscreen |
| `Mod`+`H`/`J`/`K`/`L` | Focus left/down/up/right |
| `Mod`+`Shift`+`H`/`J`/`K`/`L` | Move window |
| `Mod`+`1`…`5` | Switch workspace |
| `Mod`+`R` | Cycle column width |
| `Print` | Screenshot |
| `Mod`+`Shift`+`/` | Hotkey overlay (full list) |
| `Mod`+`Shift`+`E` | Quit niri |

## Reskin it

Everything is driven by one base16 file. Swap the palette and rebuild:

```nix
# modules/nixos/stylix.nix
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
```

…or edit `themes/kanagawa.yaml` directly.

GPG passphrase prompts use `pinentry-qt`.

## Per-project dev environments

Python 3, pip, venv, pandas, ipykernel, and openpyxl are available in the user
environment. Create a virtual environment with `python3 -m venv .venv` for
installing project dependencies. Use `--system-site-packages` to also access
the preinstalled packages inside the virtual environment.
For other language toolchains and project-specific dependencies, use direnv
and flakes per project:

```sh
# in a project repo
echo "use flake" > .envrc && direnv allow
```

```nix
# that project's flake.nix devShell, e.g.
devShells.default = pkgs.mkShell { packages = [ pkgs.nodejs pkgs.cargo ]; };
```

## Verifying changes

You can develop this on **macOS**, but a NixOS system can't be *built* there
without a Linux builder — these all work locally as pure evaluation/lint:

```sh
nix flake check                                              # evaluate everything
nix flake show                                               # list outputs
nix fmt                                                      # format (alejandra)
nix run nixpkgs#statix -- check . && nix run nixpkgs#deadnix # lint
nix eval .#nixosConfigurations.nnn.config.system.build.toplevel.drvPath
```

On a NixOS box (or with a remote/`linux-builder`) you can smoke-test in a VM:

```sh
nixos-rebuild build-vm --flake .#nnn
./result/bin/run-nnn-vm
```

### CI

[`.github/workflows/check.yml`](.github/workflows/check.yml) runs on every push
and PR:

- **eval** — `nix flake check --no-build` evaluates the whole config (the fast,
  reliable signal: catches option typos and niri schema errors).
- **lint** — `alejandra --check`, `statix`, `deadnix`.
- **build** — realises the full system closure; runs on `main` / manual
  dispatch. niri and noctalia are pulled prebuilt from their cachix caches
  (`niri.cachix.org`, `noctalia.cachix.org`), so it finishes in minutes instead
  of compiling C++/Rust from source. Delete the job if you don't want it.

> **Commit a `flake.lock`.** Generate it once on a machine with Nix
> (`nix flake lock`) and commit it, so CI and your machines resolve identical
> inputs. Until then, each run pins the latest upstream automatically.

## Notes / next steps (not included)

- Secrets: add [sops-nix](https://github.com/Mic92/sops-nix) or
  [agenix](https://github.com/ryantm/agenix).
- Desktop disks: rhea uses [disko](https://github.com/nix-community/disko);
  `hosts/nnn` still uses a generated hardware-configuration.nix.

### rhea (VPS)

Legacy-BIOS QEMU guest (SeaBIOS): GPT + 1M BIOS-boot partition + ext4 root,
GRUB, root SSH by key only. Firewall (NixOS `networking.firewall`; nixpkgs has
no ufw): public SSH 22/tcp and NetBird 51820/udp only, no ping; NetBird peers
are trusted. Accepted (public) and refused connections go to the kernel log;
`fw-report [1h|24h|7d]` on rhea (or `rhea-fw` from the desktop) shows open vs
closed ports, live connections, and those counts. CrowdSec (`hosts/rhea/crowdsec.nix`)
watches sshd, pulls the community blocklist, and bans via the iptables bouncer
(bouncer drops are not in the refused log); its web UI runs as a podman
container on :3001, NetBird/localhost only. NetBird reuses
`secrets/netbird-setup-key.age`, encrypted to rhea's host key too. First
install wipes the disk:

```sh
# Panel: mount the NixOS minimal ISO and boot it. In the VNC console:
sudo passwd root && ip a && lsblk   # IP for below; disk must match hosts/rhea/disko.nix

# From this machine:
nix run github:nix-community/nixos-anywhere -- --flake .#rhea root@<vps-ip>
```

Unmount the ISO in the panel, then deploy changes from this machine with
(`-H` is required: nh otherwise treats the IP as the hostname):

```sh
nh os switch . -H rhea --target-host root@<vps-ip> --use-substitutes
```

### Binary caches (no source builds)

niri and noctalia would otherwise compile from source (noctalia's C++ tree alone
is ~an hour). To avoid that, the flake pins **noctalia to its `cachix` branch**
— upstream force-pushes there only after a commit's package is built and pushed
to `noctalia.cachix.org`, so `inputs.noctalia.packages.<sys>.default` is always a
cache hit. It still tracks the **v5 line** (`main`), just slightly behind; the
old series lives on `legacy-v4`. niri uses niri-flake's prebuilt
`niri-stable` from `niri.cachix.org` for the same reason.

These caches are trusted in [`modules/nixos/default.nix`](modules/nixos/default.nix)
so your machine pulls binaries too. Neither input may `follows` our `nixpkgs` —
that would rebuild them against a different nixpkgs and miss the cache.

The CachyOS kernel uses the [nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel)
`release` branch with its own nixpkgs pin. The maintainer's Lantian binary cache
is no longer available, so the kernel is compiled from source (ThinLTO, slow).
It is only rebuilt when the kernel derivation changes, e.g. after updating the
`nix-cachyos-kernel` flake input:

```sh
nh os boot .#nnn
```

Reboot to load the new kernel and its matching NVIDIA driver.
