# AGENTS.md — Agent & Developer Guide for `local-machine-config`

Welcome to `local-machine-config`. This repository contains the automated machine provisioning codebase for Jackjon Butcher's personal development machines. It automates system settings, core developer CLI tools, graphical desktop environments, terminal emulators, shell configurations, Neovim/LazyVim distributions, dotfile stowing, GPG/SSH key generation and GitHub registration, and Model Context Protocol (MCP) servers.

---

## 1. High-Level Architecture & Philosophy

- **Engine:** Ansible (local connection targeting `localhost`).
- **Inventory:** `hosts` file declaring `localhost` under `all`.
- **Configuration:** `ansible.cfg` sets inventory to `./hosts` and roles path to `./roles`.
- **Target Environments:**
  - **Debian-based Linux** (Ubuntu, Debian, Linux Mint) on `amd64` and `arm64`.
  - **WSL2** (Debian/Ubuntu running under Windows Subsystem for Linux), with optional XFCE4 and XRDP desktop GUI.
  - **macOS** (Darwin) on Apple Silicon (`arm64`, Homebrew in `/opt/homebrew`) and Intel (`x86_64`, Homebrew in `/usr/local`).
  - **Windows 10/11** via MSYS2 (Ansible controller and POSIX utilities) and Scoop (native Windows developer CLIs and apps).
- **Core Principles:**
  - **Strict Idempotency:** Running the playbook repeatedly must produce zero unintended changes and never break an existing state.
  - **Defensive Execution:** Always verify binary presence, service states, and permissions using registered facts, explicit `changed_when`, and custom `failed_when` guards.
  - **Non-Destructive Backups:** Existing configurations (e.g. Neovim config, dotfiles, SSH config) are safely backed up before modification or replacement.

---

## 2. Directory Structure

```text
local-machine-config/
├── .ansible-lint             # Ansible linting rules (skips package-latest)
├── .gitattributes            # Line ending normalization (LF for yml/sh, CRLF for ps1)
├── ansible.cfg               # Local Ansible configuration (inventory and roles path)
├── hosts                     # Inventory targeting localhost
├── install.ps1               # Bootstrap & installation script for Windows (PowerShell)
├── install.sh                # Bootstrap & installation script for Linux and macOS (Bash)
├── run-playbook.sh           # Main playbook runner wrapper (handles WSL & OS path quirks)
├── README.md                 # User-facing documentation
├── common/                   # Shared tasks included across roles and playbooks
│   └── tasks/
│       ├── backup_directory.yml         # Safe file/folder backup helper (.bak)
│       ├── check_apt_sources.yml        # Runs apt-get update, fails with the broken repos and how to fix them
│       ├── install_scoop_package.yml    # Robust Windows Scoop installer & soft-repair
│       ├── manage_ssh_config_entry.yml  # Idempotent ~/.ssh/config blockinfile manager
│       ├── install_pnpm_global_packages.yml # Idempotent pnpm global installs/updates (all platforms)
│       ├── install_node_lts_nvm_sh.yml  # Installs/upgrades Node.js LTS with nvm-sh, sets nvm's default
│       ├── resolve_github_release.yml   # Newest GitHub release older than the supply-chain cutoff
│       ├── resolve_node_lts.yml         # Newest Node.js LTS release older than the supply-chain cutoff
│       ├── resolve_pnpm_executable.yml  # Finds a working pnpm on Linux/macOS (layout varies by version)
│       ├── set_os_facts.yml             # Discovers is_debian_family, is_mac, is_windows, is_wsl
│       ├── set_python_interpreter.yml   # Resolves Python interpreter & venv per platform
│       └── set_sys_architecture_facts.yml # Discovers is_amd64 and is_arm64
├── playbooks/
│   └── setup_ansible_controller.yml     # Master playbook orchestrating pre_tasks, roles, post_tasks
├── roles/
│   ├── configure_git/        # GPG & SSH key generation, GitHub registration, gitconfig
│   ├── configure_keyboard/   # Keyboard maps, XFCE & macOS workspace shortcuts, Kinto.sh/AHK
│   ├── configure_mcp_servers/# Claude Code & Antigravity (agy) CLIs, Home Assistant MCP server
│   ├── configure_msys2/      # MSYS2 path inheritance, home directory sync, Dracula theme
│   ├── configure_shell/      # Default shell (macOS Bash), Starship prompt, argcomplete
│   ├── configure_system/     # Linux file descriptor limits (limits.conf)
│   ├── install_base_packages/# OS-specific package management (apt, brew, pacman, scoop)
│   ├── install_browser/      # Google Chrome (amd64) or Firefox (arm64)
│   ├── install_docker/       # Docker Engine (Linux/WSL2) and Docker Desktop (macOS)
│   ├── install_lazyvim/      # Neovim, LazyVim starter, Cascadia Code Nerd Font, terminal fonts
│   ├── install_spacevim/     # Deprecated (retained for backward compatibility)
│   ├── install_wsl_gui/      # XFCE4 desktop + XRDP server in WSL2
│   ├── pre_flight_checks/    # gh CLI authentication, required scopes, admin checks
│   └── stow_dotfiles/        # Clones .dotfiles repo and manages symlinks via GNU Stow
└── config/
    └── spacevim/             # SpaceVim configuration fallback
```

---

## 3. Operating System Support Matrix

| Feature / Role | Debian Linux | macOS (Darwin) | Windows (Native) | WSL2 |
| :--- | :--- | :--- | :--- | :--- |
| **Package Manager** | `apt-get`, `pipx`, `cargo` | `brew`, `pipx` | `pacman` (MSYS2), `scoop` | `apt-get`, `pipx` |
| **Shell** | `bash` + `starship` | Homebrew `bash` + `starship` | MSYS2 `bash` + `starship` | `bash` + `starship` |
| **Keyboard Remap** | `kinto.sh` (`xkeysnail`), Xmodmap | Native macOS | Kinto (`AutoHotkey v1.1`) | Windows host handles Kinto |
| **Editor** | Neovim + LazyVim | Neovim + LazyVim | Neovim + LazyVim | Neovim + LazyVim |
| **Terminal Font** | Cascadia Code NF (XFCE) | Cascadia Code NF (Terminal) | Cascadia Code NF (Mintty) | Host terminal / XFCE |
| **Git / SSH / GPG** | `keychain` + `gh` + `gpg` | macOS Keychain + `gh` + `gpg` | Windows ssh-agent + `gh` + `gpg` | Inherited / agent |
| **Container Runtime** | `docker-ce` (Docker Engine) | Docker Desktop | — (runs in WSL2) | `docker-ce` (Docker Engine) |
| **Desktop GUI** | Native desktop / XFCE | Native Aqua | Windows Desktop | XFCE4 via XRDP |

---

## 4. How to Execute & Test Playbooks

### Running via the Wrapper Script (Recommended)

Always execute playbooks via `./run-playbook.sh`. The script inspects the running environment and handles WSL mounted drive permissions, custom pipx executable paths, and sudo escalation flags.

```bash
# Standard execution (prompts for sudo on Linux/macOS)
./run-playbook.sh

# Syntax check
./run-playbook.sh --syntax-check

# Target specific tags (e.g. Git configuration or LazyVim)
./run-playbook.sh --tags "configure_git"
./run-playbook.sh --tags "install_lazyvim"

# Dry run / check mode
./run-playbook.sh --check
```

### Running on Windows from PowerShell

On Windows, Ansible runs inside MSYS2. From PowerShell, use the wrapper, which finds MSYS2's bash, sets up the same environment as `install.ps1` (inherited PATH, Ansible log in `%TEMP%`) and passes all arguments through:

```powershell
.\run-playbook.ps1
.\run-playbook.ps1 --tags configure_keyboard
.\run-playbook.ps1 --syntax-check
```

Running a local `.ps1` needs an execution policy that allows it. `install.ps1` sets the user's policy to `RemoteSigned` on every run (it used to only when installing Scoop, so machines where Scoop came first kept Windows' default, which blocks scripts). To set it by hand: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. Without the wrapper:

```powershell
# Using the Scoop-installed MSYS2 bash:
& "$env:USERPROFILE\scoop\apps\msys2\current\usr\bin\bash.exe" -lc "cd /c/Users/JJB/Repos/local-machine-config && ./run-playbook.sh --syntax-check"

# To execute a full run:
& "$env:USERPROFILE\scoop\apps\msys2\current\usr\bin\bash.exe" -lc "cd /c/Users/JJB/Repos/local-machine-config && ./run-playbook.sh"
```

### Setting Up a New Windows Machine (Windows → WSL2 → XFCE)

The playbook does **not** install WSL itself; it only configures a WSL distro when run inside one. The full procedure is three runs:

1. **Windows host:** run the Windows bootstrap below from an elevated PowerShell. Stay at the machine: it prompts for `gh auth login` (browser), SSH and GPG passphrases, and the Home Assistant URL/token. Logs: `%TEMP%\local-machine-config-install.log` (transcript) and `%TEMP%\local-machine-config-ansible.log` (Ansible output — the transcript cannot capture it).
2. **Install WSL2 manually:** `wsl --install -d Ubuntu` from an elevated prompt, reboot, then launch Ubuntu once to create the Linux user. Inside WSL, run the Linux bootstrap below. This installs XFCE + XRDP (`install_wsl_gui`) and prints the RDP connection details.
3. **Inside the XFCE desktop:** connect with `mstsc.exe` to the WSL IP (not `localhost`, which collides with the Windows console session), open a terminal in the XFCE session, and run `./run-playbook.sh` again. The XFCE keyboard/workspace settings in `configure_keyboard` only apply when `XDG_CURRENT_DESKTOP == 'XFCE'` (`is_inside_xfce`), so they are skipped by the plain WSL shell run in step 2.

### Running the Bootstrap Installers

- **Windows Bootstrap:** Elevated PowerShell:
  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.ps1'))
  ```
- **Linux/macOS Bootstrap:** Terminal:
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh)"
  ```

---

## 5. Key Roles & Functionality

### `pre_flight_checks`
- Validates that `gh` CLI is installed and authenticated.
- Verifies `admin:public_key` and `admin:gpg_key` scopes are granted.
- Detects whether Windows execution has administrative privileges (`has_admin_privileges`).

### `common/tasks/set_python_interpreter.yml`
- Runs prior to gathered facts using `raw` commands.
- On Windows MSYS2: Detects whether `/mingw64/bin/python.exe` exists, provisions `~/.venvs/local-machine-config`, bootstraps pip, and points `ansible_python_interpreter` appropriately.
- On Linux/macOS: Provisions virtual environment with required Ansible modules (`pexpect`, `bcrypt`, `cryptography`, `pipx`).

### `install_base_packages`
- **Linux:** Installs system tools, Rust via `rustup`, Alacritty via `cargo`, `gh`, `lazygit` (deb or tarball depending on OS version), `fzf` from source, `starship`, Node LTS via `nvm`, `pnpm`, and `ansible-lint`.
- **macOS:** Installs Homebrew packages (`starship`, CLI utilities), `nvm`, Node LTS, `pnpm`, and global CLI utilities.
- **Windows:** Pacman packages in MSYS2, Scoop packages (`gh`, `neovim`, `lazygit`, `alacritty`, `cascadiacode-nf`, `fzf`, `ripgrep`, `fd`, `luarocks`, `sqlite`, `tealdeer`, `perl`, `starship`), removes conflicting Node installations from `C:\Program Files\nodejs`, installs AutoHotkey v1.1 via GitHub releases.
  - **nvm-windows:** Installed per-user from the official GitHub release installer (checksum-verified) into `%LOCALAPPDATA%\Author Software\nvm`, not via Scoop: nvm 2.x reports running from any other location as unsupported (`NVM4101`). Node.js versions live under `...\nvm\installs`. The path contains a space, so quote it in `command` tasks.
  - **Node.js & pnpm:** nvm-windows 2.x runs in shim mode. Its proxy shims (`%LOCALAPPDATA%\Author Software\nvm\.nodejs`) are added to the user PATH by the playbook, along with pnpm's global bin directory (`%LOCALAPPDATA%\pnpm`). pnpm is installed into the active Node.js version via npm (and listed in nvm's `auto_installed_modules`) rather than via Scoop. Roles invoke pnpm via the absolute, quoted shim path `.../nvm/.nodejs/pnpm.exe`, never `scoop which pnpm`.
- **All platforms:** Installs pnpm global packages listed in `defaults/main.yml` (`install_base_packages_pnpm_global_packages`: `neovim`, `tree-sitter-cli` with its build script allowed, and the Rafter CLI (`@rafter-security/cli`, exposing `rafter`), the local command-safety layer invoked by AI agent guard hooks) via `common/tasks/install_pnpm_global_packages.yml`, which installs missing packages and updates outdated ones.

### `configure_mcp_servers`
- Installs the Claude Code CLI (`claude`) and Antigravity CLI (`agy`) with their vendors' official install scripts if missing. On Windows they live in `%USERPROFILE%\.local\bin` and `%LOCALAPPDATA%\agy\bin`, which `install_base_packages` adds to the user PATH; the role always calls them by absolute path.
- Registers Home Assistant's MCP server (`<url>/api/mcp`, Streamable HTTP, long-lived access token as a Bearer header) for Claude Code (`claude mcp add --scope user`, stored in `~/.claude.json`) and agy (`~/.gemini/config/mcp_config.json`, `serverUrl` + `headers`). Plain `http://` local URLs work with header auth.
- The Home Assistant URL and token are **never committed**: they are prompted for on first run (token input hidden) and saved to `~/.config/local-machine-config/home_assistant.yml` (mode 0600). Leave the URL blank to skip, or pass `-e configure_mcp_servers_skip_home_assistant=true`. All token-handling tasks use `no_log`.
- To rotate the token: edit the local settings file, run `claude mcp remove -s user home-assistant`, then re-run `--tags configure_mcp_servers`.

### `install_docker`
- **Linux/WSL2:** Installs Docker Engine (`docker-ce`, `docker-ce-cli`, `containerd.io`, the Buildx and Compose plugins) from Docker's apt repository, enables and starts the `docker` service when systemd is available, and adds the current user to the `docker` group.
- **macOS:** Installs Docker Desktop via the Homebrew cask. First launch and license acceptance remain manual.
- **Windows:** Not installed — Docker runs inside WSL2 instead.

### `install_lazyvim`
- Installs the newest Neovim release older than the supply-chain cutoff (Linux; Homebrew on macOS, Scoop on Windows).
- Installs the LazyVim starter (`https://github.com/LazyVim/starter`, `.git` removed) **only when the Neovim config (`~/.config/nvim` or `%LOCALAPPDATA%\nvim`) is not already a LazyVim config**, detected by `lua/config/lazy.lua`. An existing LazyVim config, including customisations, is never touched.
- A non-LazyVim config (e.g. SpaceVim) is first moved to a timestamped `<path>.bak-<timestamp>` (plus Neovim's data/state/cache dirs); backups never overwrite each other.
- Installs Cascadia Code Nerd Font and configures the relevant terminal emulator.

### `stow_dotfiles`
- Clones `https://github.com/justJackjon/.dotfiles.git` into `~/.dotfiles`.
- Safely stows using `stow */ --adopt` followed immediately by `git restore .` to guarantee local symlinks point to the version-controlled dotfiles without corrupting the dotfiles repository.

### `configure_git`
- Manages SSH key (`ed25519` at `~/.ssh/ansible-managed/github/id_rsa`). Prompts for passphrase on creation.
- Manages GPG key (RSA 4096). Prompts for passphrase on creation.
- Registers public keys with GitHub via `gh ssh-key add` and `gh gpg-key add`.
- Sets global `user.name` ("Jackjon Butcher"), `user.email` ("jackjon@jjb.codes"), `commit.gpgsign=true`, and signing key.
- Switches git remote URL from HTTPS to SSH (`git@github.com:justjackjon/local-machine-config.git`).

---

## 6. Coding Standards & Agent Guidelines

### 1. Idempotency & State Tracking
- Never write tasks that report `changed` when no real change took place.
- For `command` or `shell` tasks, always define `changed_when` and `failed_when`.
- When checking state via shell commands (e.g. `which`, `grep`, `status`), set `changed_when: false` and handle non-zero exit codes using `failed_when: false` or `ignore_errors: true`.

### 2. Path Handling Across Windows & POSIX
- Windows runs a dual environment: PowerShell/native Windows tools and MSYS2 bash.
- Always convert paths when crossing boundaries:
  - `cygpath -u "<windows_path>"` to pass a Windows path to POSIX tools.
  - `cygpath -w "<posix_path>"` or `cygpath -m "<posix_path>"` to pass a POSIX path to native Windows executables (PowerShell, `regedit`, `mklink`).
- In Ansible tasks executing on Windows, normalize paths by replacing `~` with the user profile POSIX path and converting backslashes `\` to forward slashes `/`.

### 3. Git Commit Conventions
Commit messages in this repository adhere to the **Gitmoji + Scope** format:

```text
<gitmoji>  (<scope>): <Subject in imperative mood>
```

**Common Examples:**
- `:bug:   (configure_git): Fix idempotency in GPG key check`
- `:sparkles:   (roles): Add pinentry for gpg keys on macos`
- `:wrench:   (playbooks): Update python interpreter facts`
- `:memo:   (docs): Update AGENTS.md with execution guidelines`

**Branches:** don't commit to `main` directly. Use a short-lived branch named `<type>/<short-kebab-description>` (`feat/…`, `fix/…`, as in PRs #15–#34), and merge it with a pull request. `main`'s branch protection requires a pull request and signed commits, but it isn't enforced for admins, so a direct push from the owner's account still goes through: following this rule is up to us. Merged branches are deleted automatically.

### 4. Supply-Chain Rules
New installs must follow these rules (see the README's "Supply-Chain Safety" for the user-facing summary):
- **Never install a release younger than the cooldown.** The playbook sets `supply_chain_min_release_age_days` (default 7) and derives `supply_chain_release_cutoff` (UTC ISO 8601) and play-level environment variables from it: `PIP_UPLOADED_PRIOR_TO=<supply_chain_release_cutoff>` (pip >= 26, so pipx too; an absolute timestamp, because pip 26.0 rejects durations such as `P7D`; `install.sh` and CI compute theirs with `date -u -d '7 days ago'`), `npm_config_min_release_age=7` (days) and `pnpm_config_minimum_release_age=10080` (minutes). Task-level `environment:` merges with them, so tasks don't need to repeat them. Every run prints one `raw module does not support the environment keyword` warning, from the `raw` tasks that run before Python is set up. It's harmless; avoiding it would mean splitting the playbook into two plays. Like any Ansible warning it goes to stderr, so redirecting `.\run-playbook.ps1`'s stderr (`*>`, `2>&1`) makes PowerShell 5.1 report a failure, because the wrapper sets `$ErrorActionPreference = 'Stop'`, even when the play succeeded. Verified in WSL2 Ubuntu (Nov 2026, pip 26.3, npm 11.20, pnpm 12.23): each tool skipped the too-new version, including pnpm for `@latest`, `pnpm outdated` and `pnpm self-update`. `npm view` ignores the gate; use `npm pack <pkg> --dry-run --json` to see what it resolves to.
- **GitHub releases:** use `common/tasks/resolve_github_release.yml`, never `releases/latest`, and pass the asset's `digest` to `get_url`'s `checksum`. Its default tag regex skips non-version releases such as Neovim's `stable` and `nightly`.
- **Never download from a branch** (`master`, `HEAD`, `main` of someone else's repo). Pin a commit or release tag and keep a `sha256:` checksum in the repo (GitHub's digest where it exists; older assets have none). GitHub source archives (`archive/<sha>.zip`) are pinned by commit without a checksum, because their bytes aren't guaranteed stable.
- **Never pipe a download into a shell** (`curl | bash`, `irm | iex`). Download to a file with `get_url`, run it, then remove it. Prefer an installer's version or channel option (Claude Code: `stable`; Starship: `--version`; pnpm: `PNPM_VERSION`).
- **Build with lockfiles:** `cargo install` with `locked: true`.
- **Upgrade, don't just install.** Re-running the playbook must move each tool to the newest version the cooldown allows, and must never downgrade a newer one (compare with the `version` test first; installers and `scoop update` will happily downgrade). `creates:`, `pipx install` and `scoop install` alone never upgrade. Node.js LTS: `common/tasks/resolve_node_lts.yml` (nodejs.org's `index.json`), installed by `install_node_lts_nvm_sh.yml` (Linux/macOS) or nvm-windows, which then uninstall every other Node.js version (`install_base_packages_remove_old_node_versions`, default true; verified in WSL2 and on Windows by installing v24.21.0 next to v26.13.1). While several versions are installed, find Node's bin directory from nvm's `default`, never `find ... | head -n 1`. Scoop: buckets and Scoop core are reset to their last commit before the cutoff after `scoop update`, and apps are updated only when `files/scoop_versions.py` reports the bucket version newer than the installed one.
- **Ansible itself** is upgraded by `install.sh` (`pipx upgrade ansible`), never by the playbook (replacing its venv mid-run could break the run). It's one pipx venv, `ansible --include-deps`, so `ansible-playbook` uses the collections bundled with the `ansible` package, which come through pip's cooldown. Don't add `ansible-galaxy collection install`: Galaxy has no cooldown, and `~/.ansible/collections` shadows the bundled collections, so those copies never update. MSYS2's and Homebrew's `ansible` packages bundle the collections too.
- **Accepted exceptions** (no release-age setting exists): apt, Homebrew, pacman, Scoop core's own code before the reset, rustup's toolchain, Google Chrome's `.deb`. nvm (nvm-sh) is pinned in the repo and never upgraded; nvm-windows is installed once. Claude Code (stable channel) and agy update themselves. Mark each exception with a `# NOTE:` explaining why it isn't gated.
- **CI:** `.github/workflows/lint.yml` (syntax check + `ansible-lint --offline`), tools pinned in `.github/ci/requirements.txt`, actions pinned by SHA, updates proposed by Dependabot with a 7-day cooldown. Pre-existing findings are baselined in `.ansible-lint-ignore` (by file and rule); don't add to it, fix new findings instead. GitHub secret scanning and push protection are enabled on the repository.

### 5. Preserving Comments & Rationale
- Existing tasks contain critical `# NOTE:` comments explaining why certain workarounds exist (e.g., WSL world-writable mounts, Cloudflare blocks on AutoHotkey Scoop manifests, nvm-windows 2.x proxy shims shadowing Scoop's on PATH).
- **Never remove or overwrite `# NOTE:` comments** unless the workaround is being intentionally retired.

### 6. Verification Checklist for Agents
Before finishing any modification in this repository:
1. Run `./run-playbook.sh --syntax-check` to verify YAML validity and syntax.
2. If working on a specific role, verify changes with the corresponding tag (e.g. `--tags "configure_git"`).
3. Ensure `.gitattributes` line endings are respected (LF for Linux/macOS/Ansible files, CRLF for PowerShell).
4. Run `git status` to verify no unexpected files or temporary artifacts remain.

---

## 7. Known Pitfalls & Lessons Learned

Hard-won findings from debugging real runs. Read this before changing the Windows roles. Each entry notes where it was **verified**; entries marked *by analogy* were applied to other platforms without being run there yet.

### Ansible `command` module expands `$VARS` — this wiped a user PATH once
- **Symptom:** a PowerShell script embedded in `ansible.builtin.command` silently misbehaved; a PATH-update task filtered out every entry and wrote back only the additions.
- **Cause:** `command` has `expand_argument_vars: true` by default, so `$NAME` matching an environment variable is substituted before execution. Bash's `$_` (last command, e.g. `/usr/bin/python3.14`) replaced PowerShell's pipeline variable `$_`. Unknown names (`$current`) survive, which makes this easy to miss.
- **Rule:** every `command` task containing a literal `$` (PowerShell, etc.) **must** set `expand_argument_vars: false`. `shell` tasks are unaffected. Any task that rewrites PATH must also guard against dropping entries and preserve `REG_EXPAND_SZ` (read the raw value with `DoNotExpandEnvironmentNames`; never round-trip through `[Environment]::Get/SetEnvironmentVariable`, which writes `REG_SZ`). Verified on Windows; a repo-wide scan found no other affected `command` tasks.

### MSYS2 is retiring its `mingw64` repo
- **Symptom:** `pacman` fails with `package 'mingw-w64-x86_64-…' was not found` (pacman writes this to stderr, which the PowerShell transcript does not capture).
- **Removed so far:** `github-cli`, `python-pipx`, `python-userpath`, `jq`, `lua-luarocks`, `sqlite3`, `tldr`. Replacements: `gh`, `luarocks`, `sqlite`, `tealdeer` via Scoop; MSYS `jq`. `ucrt64` is MSYS2's recommended environment, but migrating is a larger change that has not been attempted.
- **Diagnose quickly:** `pacman -Si mingw-w64-x86_64-<name>` per package.
- **Partial upgrades break:** the playbook upgrades only its own pacman packages (`state: latest`). When MSYS2 restructures packages (Nov 2026: `gcc-libs` split into `libstdc++`/`cc-libs`; `gdb-multiarch` dropped from the toolchain group but still pinning `gdb=17.1`), that fails with `could not satisfy dependencies`. `install.ps1` now runs a full `pacman -Syu` on every run, before Ansible (Ansible is itself a pacman package, and a core update ends every MSYS2 process). It retries on HTTP 429 from the mirrors (downloads stay cached), and uses a copy of `pacman.conf` without `DisableDownloadTimeout`, so a stalled download fails and is retried instead of hanging. If `.\run-playbook.ps1` alone hits this, run `pacman -Syu` (twice) from PowerShell first. A large backlog is slow on a scanned corporate disk (190 packages took about 45 minutes). Verified on Windows: the upgrade, then `--tags install_base_packages` with `failed=0`. `unzip` was previously only present transitively and is now listed explicitly (needed by `unarchive` for the Kinto zip). Windows-only.

### nvm-windows 2.x is a different product from 1.x
- Scoop's `nvm` jumped to 2.x. It refuses to support running outside `%LOCALAPPDATA%\Author Software\nvm` (`NVM4101`), so it is installed from the official release installer (silent Inno Setup flags: `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LANG=english`; inspect an installer without running it via `innounp -x -m`).
- It runs in **shim mode**: `node`/`npm`/`pnpm`/`yarn` are proxy executables in `...\nvm\.nodejs`. Its `pnpm` proxy shadows any other pnpm on PATH and errors (`pnpm is not installed for this Node.js version`) unless pnpm is installed into the active Node version. Node 25+ no longer bundles corepack, so `corepack enable` is not an option; use `npm install -g --allow-scripts=pnpm pnpm`.
- `nvm install` output changed to `SKIPPED: vX.Y.Z is already installed`; parse a bare `vX.Y.Z`.
- Its `.shim` directory and proxy executables carry explicit ACLs (user: read/execute + `WRITE_DAC` only). Deleting them needs `icacls <dir> /grant <user>:F /T` first — **not** `(OI)(CI)F`, whose inheritance flags leave files' explicit ACLs unchanged.
- Upgrading from a Scoop install makes the official installer adopt the old Node root; the playbook resets it with `nvm cfg reset root`. Windows-only (Linux/macOS use nvm-sh, unaffected).

### npm 11.20+ blocks install scripts by default
- Packages that set themselves up in `preinstall`/`postinstall` (pnpm itself) need `--allow-scripts=<name>`. Verified on Windows; applied *by analogy* to the Linux npm fallback in `install_base_packages/tasks/linux.yml` (not yet exercised on Linux: the standalone installer succeeded there). macOS installs pnpm via Homebrew.

### pnpm's standalone installer moved the binary in v11 (Linux/macOS)
- **Symptom:** `Install pnpm packages` fails with `[Errno 2] No such file or directory: b'/home/<user>/.local/share/pnpm/pnpm'`, although `pnpm` works in a new shell.
- **Cause:** pnpm <= 10 put its binary at `$PNPM_HOME/pnpm`. pnpm >= 11 installs into `$PNPM_HOME/global/v11/...` and links a launcher at `$PNPM_HOME/bin/pnpm` (its `pnpm setup` block in `~/.bashrc` puts `$PNPM_HOME/bin` on PATH). Separately, `install_lazyvim` deleted `$PNPM_HOME/bin/pnpm` as a pnpm 10-era "circular shim", which would have removed the real launcher.
- **Fix:** never hard-code the pnpm path on Unix. Include `common/tasks/resolve_pnpm_executable.yml`, which tries `bin/pnpm`, `pnpm`, then PATH, keeps the first that runs `--version`, and sets `resolved_pnpm_executable_path`. Verified in WSL2 Ubuntu (pnpm 12.23.0); macOS uses the same resolver *by analogy* (it finds Homebrew's pnpm via PATH).

### Several `gpg`s on Windows — only one keyring is right
- Git for Windows' bundled gpg (the `gpg` Scoop shim) and MSYS2's gpg (both 2.4.x) share `~/.gnupg`, where `configure_git` creates the signing key. Scoop's `gnupg` (2.5.x) was a separate portable install with its own keyring (`scoop/apps/gnupg/current/home`), and its `bin` landed on the user PATH ahead of `scoop/shims`, so every signed `git commit` from a Windows shell failed with `No secret key`. Scoop's `gnupg` is no longer installed (and is purged if present).
- **Diagnose:** run `<gpg.exe> --version` (shows `Home:`) and `--list-secret-keys` for each candidate. Windows-only.

### Scoop's pnpm leaves config behind
- Scoop's pnpm manifest writes `storeDir`/`cacheDir`/`stateDir` (pointing into `scoop/apps/pnpm`) into pnpm's global `config.yaml`. Removing Scoop's pnpm does not remove them, so the next pnpm recreates the directory and Scoop lists a phantom `Install failed` app. The playbook deletes those keys. Windows-only.

### Windows PowerShell 5.1 couldn't find `Get-FileHash` under Ansible
- **Symptom:** `Run Claude Code installer` failed with `The term 'Get-FileHash' is not recognized`.
- **Cause:** when the run starts from PowerShell 7, its `PSModulePath` (PowerShell 7's module directories first) is inherited through MSYS2, which renames it to `PSMODULEPATH`. `powershell.exe` (5.1) then can't autoload its own built-in modules. Overriding `PSModulePath` from bash has no effect: it's a second variable.
- **Fix:** `run-playbook.sh` unsets `PSMODULEPATH` on MSYS2, so `powershell.exe` rebuilds its default path. Verified on Windows from PowerShell 7: reproduced in MSYS2 bash, then both AI CLI installers succeeded, and a re-run reported no changes.

### Debugging Windows runs
- `Start-Transcript` in Windows PowerShell 5.1 does not capture native executables' output, so `install.ps1` sets `ANSIBLE_LOG_PATH`. Don't pipe the playbook through `Out-Host` to work around it: that line-buffers output and hides prompts that don't end in a newline (passphrases).
- When an agent drives PowerShell, native-argument quoting in 5.1 mangles embedded double quotes (`gh --jq '...'`, `bash -lc "..."`). Write scripts to a file and run the file instead.
- A shell started before Scoop was installed won't have `~\scoop\shims` on PATH; rebuild PATH from the registry (`Machine` + `User`) before concluding a tool is missing.

### ansible-core 2.22's `git` module can't update a shallow tag clone
- **Symptom:** the second and later runs fail at `Clone fzf repository` with `'NoneType' object has no attribute 'startswith'` (traceback via `ANSIBLE_DISPLAY_TRACEBACK=always`: `get_head_branch` in `modules/git.py`).
- **Cause:** `depth: 1` + a tag `version` leaves a detached HEAD with no `refs/remotes/origin/HEAD`; on update, the module reads that missing ref as `None`. Fresh clones are fine.
- **Fix:** fzf is cloned only fresh. Its current tag is checked with `git describe --tags --exact-match`, and an outdated clone is deleted and re-cloned. Don't combine `depth` with in-place updates of a tag checkout. Verified in WSL2 Ubuntu.

### SSH to GitHub fails inside the XFCE session (WSL2) although it works in a plain WSL shell
- **Symptom:** `git pull` in an XFCE terminal fails with `Permission denied (publickey)`.
- **Cause:** XFCE starts its own, empty `ssh-agent`, and the whole session (including terminals) inherits its `SSH_AUTH_SOCK`. The key lives in keychain's agent. With no `~/.ssh/config` on Linux, ssh only tried the default key names, never `~/.ssh/ansible-managed/github/id_rsa`.
- **Fix:** `configure_git` now writes the same `Host github.com` block on Linux as on Windows (`IdentityFile`, `IdentitiesOnly`, `AddKeysToAgent`), so ssh offers the right key and asks for the passphrase if the current agent lacks it. **Diagnose:** `ssh -vT git@github.com` shows which keys are offered; `ssh-add -l` shows what the current agent holds. Verified in WSL2 Ubuntu.

### Deprecations to avoid (ansible-core 2.22)
- **Injected facts:** use `ansible_facts.user_id` (and so on), never top-level fact variables such as `ansible_user_id`. `INJECT_FACTS_AS_VARS` stops defaulting to true in a later ansible-core release.
- **apt repositories:** use `ansible.builtin.deb822_repository` (writes `<name>.sources`; needs `python3-debian`), not `apt_repository` (removed in ansible-core 2.25). When migrating, delete the old `<name>.list`, and refresh the apt cache yourself: deb822_repository doesn't. The gh and Docker repositories were migrated and verified in WSL2 Ubuntu.

### Kinto on Windows ran but remapped nothing
- **Symptom:** the Kinto tray icon shows, but Cmd-style shortcuts (Alt+A as select all on a Windows layout) do nothing.
- **Cause:** upstream `windows/kinto.ahk` is a template with every remap commented out. Kinto's `setup.py` renders it with perl, uncommenting lines tagged `; Default` and `; WinModifiers` or `; MacModifiers`. The playbook's re-implementation of `setup.py` copied the file without that step.
- **Fix:** `configure_keyboard` applies `setup.py`'s regexes with `replace` to the extracted copy, then copies it into `~/.kinto` and restarts Kinto if it changed. The keyboard type is `configure_keyboard_windows_kinto_kbtype` (`win` or `mac`; `win` when the key left of the spacebar sends Alt, including Logitech multi-OS keyboards in Windows mode). Verified on Windows.
- **Don't use Kinto's tray "Keyboard Types" menu or Autodetect:** `toggle_kb.bat` comments lines out with a `; ` prefix but uncomments only one, so already-commented lines end up double-commented and switching back never restores them. Change the variable and re-run instead (the playbook re-renders from upstream).
- **Cmd+C does nothing, Opt+C copies:** the keyboard is in Mac mode (Cmd sends Win, Opt sends Alt) while Kinto expects `win`. Logitech keyboards keep the mode per connection (F1-F3), so one machine can work while another doesn't. Hold Fn+P (Windows) or Fn+O (Mac) for 3 seconds. **Diagnose:** a temporary AutoHotkey script with `~*LWin::`, `~*LAlt::` and `~*LCtrl::` hotkeys that log `A_ThisHotkey` shows the keys Windows receives, including over Remote Desktop (`msrdc.exe` is in Kinto's `remotes` group, so the client machine's Kinto passes keys through). Verified on an Azure Dev Box.
- **`regedit.exe` always prompts for elevation**, which failed an unattended run (`The operation was canceled by the user`). Kinto's `theme_ubuntu.reg` only writes `HKCU\Console`, so it's imported with `reg.exe import`. Verified on Windows.

### British - Mac characters on a UK PC keyboard
- **Goal:** the same characters on every system: Shift+2 = `@`, Shift+' = `"`, `§ ±` above Tab, `\ |` left of Enter, `` ` ~ `` left of Z, Opt+3 = `#`, Opt+2 = `€`. A keyboard's Mac/Windows mode (Logitech Fn+O) only changes the modifier keys; characters come from the OS layout.
- **Windows:** no built-in Apple UK layout. A custom layout DLL (Keyboard Layout Creator) needs admin, and it would put `#` on AltGr, which Kinto's Option key (sent as left Alt) can't reach. Instead, `files/snippets/kinto/windows_mac_gb_layout.ahk` is added to the rendered `kinto.ahk` (`configure_keyboard_windows_mac_gb_layout`). It applies only while the active window uses the "United Kingdom" layout (high word of the HKL `0x0809`), and not in remote desktops. It must live inside Kinto's script: AutoHotkey hotkeys ignore keys sent by other AutoHotkey scripts, so a separate script never sees Kinto's Alt.
- **The UK layout must be installed:** an en-US Windows (an Azure Dev Box) had only the US layout, so Shift+3 typed `#` and Opt+2/Opt+3 did nothing useful. `configure_keyboard` adds the UK keyboard (`0809:00000809`) to the first language with `Set-WinUserLanguageList` and makes it the default with `Set-WinDefaultInputMethodOverride`; the display language and the US keyboard stay. It applies from the next sign-in; until then, switch the taskbar's layout indicator to UK. Verified on the Dev Box: changed on the first run, `ok` on the second, and the characters typed correctly once switched.
- **Testing on Windows:** synthetic `SendInput` presses check plain keys reliably (all passed), but not Kinto's remapped modifiers: injected Cmd+A failed, although it works on the real keyboard. Opt+2 and Opt+3 need a real key press.
- **XFCE (native Linux):** xfconf `keyboard-layout` `/Default/XkbLayout=gb`, `/Default/XkbVariant=mac` (xkb's "English (UK, Macintosh)"), then `XkbDisable=false`. Only runs inside an XFCE session that isn't in WSL. Applied *by reading xkb's `symbols/gb`*; not yet run.
- **macOS:** the built-in "British" input source (not automated).

### Mac-style keys in WSL2's XFCE session (Kinto can't run there)
- **Why not Kinto:** Windows' Kinto ignores Remote Desktop windows (its `remotes` group), and only sees `mstsc.exe`, not the app inside. Linux's Kinto (xkeysnail) grabs a physical keyboard device (`/dev/input/event*`). WSL2's kernel now has `uinput`, but XRDP's keys arrive through `xorgxrdp`, not an input device.
- **Instead:** `configure_keyboard` sets `/etc/xrdp/xrdp_keyboard.ini`: `rdp_layout_gb=gb(mac)`, plus a `[rdp_keyboard_local_machine_config]` section (`keyboard_type=4`, `keyboard_subtype=1`, `options=ctrl:swap_lalt_lctl_lwin`: xkb's version of Kinto's Windows-keyboard swap, Cmd → Ctrl, Ctrl → Super, Opt → Alt). XRDP reads the file on each connection, so reconnecting applies it; `/var/log/xrdp.log` logs the result (`xrdp_load_keyboard_layout: ... layout [gb(mac)] options [...]`).
- **`options` in `[default]` is ignored** (the first attempt): `xrdp_load_keyboard_layout` (`libxrdp/xrdp_sec.c`, xrdp 0.10.1) reads `model`/`variant`/`options` only from a section matching the client's `keyboard_type`/`keyboard_subtype`, and from `[default]` only `rdp_layouts`/`layouts_map`. Windows' client sends type 4, subtype 0, and xrdp turns subtype 0 into 1. It stops reading a section at an unexpected item, so keep the section's items in that order. Verified by a Python mirror of that function against the edited file; the live session was fixed with `setxkbmap` until the next connection. Kinto's per-app terminal behaviour is reproduced in Alacritty (`files/alacritty/wsl_xfce_mac_keys.toml`, installed to `~/.config/local-machine-config/alacritty.toml` and imported by the dotfiles' `alacritty.toml`; Alacritty skips missing imports). Physical Ctrl+key (Super) sends control characters, and Cmd+C/V copy and paste. Other terminals (xfce4-terminal) get only the swap.
- **Keyboard type 7 from an Azure Dev Box:** a Windows machine without a physical keyboard, itself used over Remote Desktop, sends type 7 (subtype 0), so it matched no section and got `options []` (no swap, so no Cmd+C/V or Opt+2/3). There is now a second managed section for type 7. In xrdp 0.9.24 the last section whose `keyboard_type` matches wins, and a later subtype mismatch resets the match to `[default]`. `model`/`options` already read are kept, so Japanese clients (type 7, subtype 2) still get `[rdp_keyboard_jp]`'s `pc105` and the same default layouts. Check the `keyboard_type`/`options` lines in `/var/log/xrdp.log`. Verified on a Dev Box: Cmd+C/V and Opt+2/3 work in Alacritty and Chrome.- **XFCE shortcuts:** with Ctrl acting as Super, XFCE's `<Super>r/p/e` would take Ctrl+R/P/E, so they're reset in `/commands/custom` (the active set when `override` is true). A running `xfsettingsd` keeps the old key grabs after that (Ctrl+R still opened the app finder), so it's restarted with `xfsettingsd --replace`.
- **Opt+2/Opt+3 (`€`, `#`):** xkb's Mac layouts put them on Right Alt, and Opt is Alt here. `files/xkb/lmc-mac-option-keys` patches the live keymap for those two keys: a key type maps Alt to level 3, and `RedirectKey(clearmods=Mod1, mods=Mod5)` re-sends the key as AltGr+key. Without the redirect, Chrome took Alt+2/3 as switch-tab and Alacritty sent Escape + `#`. xrdp reloads the keymap on every connection and can't load custom key types, so the script runs with `--watch` from XFCE autostart and re-applies within 2 s. **Tried and failed:** XFCE `<Alt>` command shortcuts never fired under this keymap (even the built-in Alt+F2 didn't), and typing the character with `xdotool` from an `xbindkeys` grab delivered nothing. Verified on an idle XRDP session with `xdotool` (since removed): Alacritty and Chrome type `#`, `€`, `@`, `£` correctly, and Opt+B is still Meta-B.
- **Testing in an XRDP session from the host:** `wsl -d Ubuntu -- bash script.sh` with `DISPLAY=:<n> XAUTHORITY=~/.Xauthority` (WSLg's `/tmp/.X11-unix` hides xrdp's sockets, but X clients still connect). Send keys with `xdotool key` (XTest; `--window` bypasses grabs), capture bytes in `alacritty -e sh -c 'stty raw -echo; dd bs=1 count=N | od -An -tx1'`, and read Chrome text from its window title (`oninput="document.title=..."`). Use an idle session, not the one the user is in.
- **Don't** set the xfconf keyboard layout in WSL: xfsettingsd would replace XRDP's xkb options.
- **Verified:** the ini edits are idempotent (tested on a copy), and Alacritty 0.17 loads the bindings with no config errors (a bad key name is reported, so the check works). **Over a real RDP connection:** the user confirmed Mac-style shortcuts in Chrome, and the Alacritty bindings were verified in a new window (`Ctrl+C` → `03`, `Cmd+C` copies). Alacritty windows opened before the import existed don't load it. Until the options apply, the bindings make physical Ctrl+C copy instead of interrupting, so check `options` in xrdp.log after changing this.
- **Windows:** `alacritty.exe` is added to Kinto's `terminals` and `posix` groups. Upstream Kinto doesn't list it, so Alacritty got GUI mappings (Cmd+C interrupted).

### `gh` logins on one machine revoked the other's token
- **Symptom:** Windows and WSL took turns failing pre-flight with `gh CLI is not authenticated` (`gh auth status`: HTTP 401, token invalid). Each failed after the other one logged in.
- **Likely cause (not confirmed):** GitHub keeps at most 10 OAuth tokens per user, app and scope set, and revokes the oldest. `install.sh` and `install.ps1` ran `gh auth login` on every run, creating a new token each time.
- **Fix:** both installers skip the login when `gh auth status -h github.com` succeeds and lists `admin:public_key` and `admin:gpg_key` (the same test as `pre_flight_checks`). `install.sh` also no longer kills Chrome when it skips the login. Verified in bash and PowerShell with a logged-in config and an empty `GH_CONFIG_DIR`.
- **Reusing a token in WSL:** `/mnt/c/Users/<user>/scoop/shims/gh.exe auth token </dev/null | gh auth login -h github.com --with-token`. Without `</dev/null`, the Windows `gh.exe` waits on the terminal and the pipeline hangs.
- **`install.sh` and the gh apt source:** once the playbook has written `github-cli.sources`, `install.sh` only upgrades gh instead of adding `github-cli.list` again (which apt reports as a duplicate source).

### Prompts appeared only after typing the answer (`install.sh`, Linux/macOS)
- **Symptom:** the Home Assistant URL prompt waited for input before its question was shown.
- **Cause:** `install.sh` sends all output through `tee` to its log, so Ansible's stdout was a pipe and a `pause` prompt without a trailing newline stayed buffered.
- **Fix:** `install.sh` runs the playbook on the original terminal (`1>&3 2>&4`). The playbook's output goes to `run-playbook.sh`'s Ansible log, not the install log. Verified in WSL2 under a pseudo-terminal: before the fix, the typed reply appeared before the question, and after it, the question came first. The same rule is why `install.ps1` doesn't pipe the playbook through `Out-Host`.

### Re-runs didn't upgrade most tools
- **Found while adding the supply-chain cooldown (Nov 2026):** a re-run upgraded apt/Homebrew/pacman packages, pnpm and its global packages, pip packages, Neovim (Linux), lazygit and fzf, but nothing else. Node.js (`creates:` on Linux/macOS), Starship (only if missing), Linux pipx packages (`pipx install`), Windows pnpm (`creates:`), every Scoop app (`scoop install` only) and Ansible's collections (Galaxy, installed once) stayed at the version first installed.
- **Fix:** each now upgrades to the newest version the cooldown allows (see "Supply-Chain Rules" above). Verified in WSL2 Ubuntu (Node.js, Starship, fzf, pipx, the Ansible venv migration) and on Windows (Scoop, Node.js, pnpm). The Linux source-built tools that need sudo (Alacritty, lazygit's tarball) were checked only up to the download.

### Machines set up before the cooldown failed in WSL (pip and pipx)
These passed on a fresh machine but failed on one the playbook had set up before (WSL2, Ubuntu 24.04):
- **`--uploaded-prior-to error: invalid value: 'P7D'`** (`install.sh`): pipx's shared venv kept the pip it had (26.0.1), and pip 26.0 reads `PIP_UPLOADED_PRIOR_TO` but accepts only an absolute datetime. Durations came in a later pip, which a fresh pipx venv gets. **Fix:** `install.sh`, the playbook and CI pass an absolute UTC timestamp. Verified in WSL2: pipx's shared pip then upgraded itself (26.0.1 → 26.3) and Ansible installed.
- **`Unknown metadata version 0.5`:** a pipx venv created by a newer pipx (here `semgrep`, installed by the playbook before 7f9be32 removed Semgrep, through `~/.venvs/local-machine-config/bin/pipx` 1.8) makes every command of Ubuntu 24.04's apt pipx (1.4.3) fail, including `pipx list`. Removed by hand with the newer pipx: `~/.venvs/local-machine-config/bin/pipx uninstall semgrep`.
- **`The pipx tool must be at least at version 1.7.0`:** `community.general.pipx` in Ansible 14 requires it, and Ubuntu 24.04 has 1.4.3. **Fix:** `install_base_packages` calls `/usr/bin/pipx install` and `pipx upgrade` with `command` (changes detected from `installed package`/`upgraded package`). Don't switch to a newer pipx for these venvs: it rewrites their metadata, and apt's pipx (used by `install.sh`) can then no longer read them. Verified in WSL2 with the tasks in a playbook without `become`: an install, then a re-run with no changes.

### `sudo.ws: not found` on Ubuntu 24.04
- **Symptom:** `Install python3-venv package on Debian-like systems` failed with `/bin/sh: 1: /usr/bin/sudo.ws: not found`.
- **Cause:** `set_python_interpreter.yml` chose `sudo.ws` when `'found' in sudo_ws_check.stdout`, which is also true for `not_found`. Only Ubuntu releases without sudo-rs (24.04 and earlier) lack `sudo.ws`, so it passed on 26.04.
- **Fix:** compare the trimmed output exactly. Verified in WSL2 Ubuntu 24.04: the check runs and `ansible_become_exe` stays unset.

### `Failed to update apt cache after 5 retries: ` with no reason
- **Symptom:** `Install python3-venv package on Debian-like systems` retried five times and failed with an empty reason.
- **Cause:** a repository the playbook doesn't manage (HashiCorp's, added by hand) had rotated its signing key (`NO_PUBKEY`). `apt-get update` only warns about it, but the apt module's cache update (python-apt) fails outright and drops the message.
- **Fix:** `set_python_interpreter.yml` includes `common/tasks/check_apt_sources.yml` before its first apt task, which no longer updates the cache itself. It runs `apt-get update` once and, on any error or failed repository, stops with the errors, the sources files of the failing hosts, and how to fix them (re-download the vendor's key to its `signed-by` keyring, or delete the sources file). Fixing the repository is a one-off; the check costs one `apt-get update`. Verified in WSL2 Ubuntu 24.04 as root: a clean run, a `NO_PUBKEY` repository, a `Signed-By` conflict, and `--check` mode.

### `pnpm self-update` from pnpm 10 left a pnpm that needs Node.js (Linux)
- **Symptom:** `Update pnpm` failed with `pnpm's native binary was not installed, and there is no Node.js to run pnpm without it.`
- **Cause:** a machine set up with pnpm 10 (the `$PNPM_HOME/pnpm` layout, `~/.bashrc` putting `$PNPM_HOME` on PATH) ran `pnpm self-update` without Node.js on PATH. pnpm 10 installed pnpm 12 into `.tools/@pnpm+exe/<ver>` without running its install script, which provides the native binary, still exited 0, and pointed `$PNPM_HOME/pnpm` at it. That pnpm only works with Node.js on PATH, which the resolver adds, so it was chosen.
- **Fix:** pnpm counts as installed only when the resolver picks `$PNPM_HOME/bin/pnpm` (the standalone installer's v11+ launcher). Anything else is replaced by the standalone installer, as on a fresh machine; it also rewrites `~/.bashrc`'s pnpm block to `$PNPM_HOME/bin`. The old launchers and `.tools` stay, unused. Verified in WSL2 Ubuntu 24.04: from the broken state it installed 12.22.0 (the cooldown skipped 12.23.0), `bin/pnpm --version` works without Node.js, `self-update` then works, and a re-run reports no changes.
### Claude Code's update channel
- `configure_mcp_servers` merges `configure_mcp_servers_claude_settings` (`autoUpdatesChannel: stable`) into `~/.claude/settings.json`, keeping the other settings and their order. A settings file that isn't valid JSON fails the run instead of being overwritten. Verified in WSL2 and on Windows (where it was `latest`).

### lazygit's release assets were renamed
- **Symptom (found while age-gating it):** the source install of lazygit (Debian < 13, Ubuntu < 25.10) built `lazygit_<ver>_Linux_x86_64.tar.gz`, but v0.66.3's asset is `lazygit_0.66.3_linux_x86_64.tar.gz`, so the download would 404.
- **Fix:** the asset is chosen from the release's asset list, matched case-insensitively and by architecture (`x86_64` or `arm64`), and downloaded with its GitHub digest. Verified the selection and download in WSL2 Ubuntu; the install itself runs only on older releases.

### Debugging WSL runs from the Windows host
- An agent on the Windows host can read and run things in WSL directly, without being installed there: `wsl -d Ubuntu -- bash -lc "..."`. `run-playbook.sh` always appends Ansible's output to `${TMPDIR:-/tmp}/local-machine-config-ansible.log` (override with `ANSIBLE_LOG_PATH`), so `tail -200 /tmp/local-machine-config-ansible.log` shows the latest run. `/tmp/local-machine-config-install.log` is written only by `install.sh`. WSL can see the Windows checkout at `/mnt/c/Users/<user>/Repos/local-machine-config`, so you can test edits before pushing them.
- `sudo` in WSL needs the user's password, so an agent can't do a full run. Test a change with a small playbook that skips `become`, then have the user re-run `./run-playbook.sh` in WSL.
- **Never copy large directories inside WSL on a nearly full Windows disk.** `ext4.vhdx` grows until C: is full. The resulting I/O errors corrupted ext4, and the fs later fell back to `emergency_ro` (`EXT4-fs error ... Remounting filesystem read-only` in `dmesg`). Without admin rights (`wsl --mount` needs them), repair it while it is read-only: `wsl -d Ubuntu -u root -- e2fsck -fy /dev/sdX`, repeated until a pass returns 0, then `wsl --shutdown` immediately. A single pass wasn't enough: the fs went read-only again 51 s after the next boot. `wsl --manage <distro> --set-sparse true --allow-unsafe` plus `fstrim -v /` gives space back to Windows, but the setting is marked unsafe (corruption risk), and setting it back to false needs free space roughly equal to the VHD's size. Verified on a Dev Box.
### `install_lazyvim` used to replace the Neovim config on every run
- It backed up and re-cloned the starter unconditionally. On Linux/macOS the shared `backup_directory.yml` also deleted the previous fixed-name `.bak` first, and passed `~` paths to `ansible.builtin.command` (no shell, so `~` was never expanded and `mv` failed silently). Now gated on `lua/config/lazy.lua`, with timestamped backups and expanded paths. Verified on Windows (existing config untouched; fresh install clones the starter). The Linux/macOS backup path is fixed *by analogy* and not yet run there.

### Tasks that reported `changed` on every run (fixed)
A second run should report only real changes (apt upgrades, new package versions, and so on). These used to report `changed` on every run, and are worth knowing as patterns to avoid:
- **`community.general.pnpm` with `global: true`** reinstalled everything, because pnpm >= 11 has no global `pnpm-lock.yaml`. Use `common/tasks/install_pnpm_global_packages.yml`, which compares `pnpm list -g --json` and `pnpm outdated -g --format json` (exits 1 when anything is outdated). Verified in WSL2 and on Windows.
- **Download → install → delete the download** (Chrome `.deb`, Nerd Font archive) re-downloads on every run. Check the installed state first (`dpkg-query`, a stat of an installed file). Verified in WSL2.
- **"Remove, then unpack"** (`/opt/nvim-*`) rebuilds every run. Compare the installed version with the release tag instead. Verified in WSL2. A `get_url` of a `latest` URL to a fixed `dest` also never re-downloads, so it never upgraded.
- **apt recommends:** `python3-pynvim` recommends apt `neovim`, which `install_lazyvim` removes in favour of the release tarball. So the two tasks undid each other across runs. Install it with `install_recommends: false`. Verified in WSL2.
- **`creates:` with `changed_when: rc == 0`** (AutoHotkey): a `creates` skip still has rc 0. Gate with a stat and `when:` instead. Windows, applied by reading the code.
- **Kinto Startup entry (Windows)** was a `cmd /c mklink` symlink, which needs admin rights or Developer Mode, used a `creates:` path that never matched (so it ran every run), and was found missing after a reboot, leaving Kinto not running. It is now a `.lnk` shortcut (`WScript.Shell`), created only when absent, and Kinto is started only if no `AutoHotkey` process is running `kinto.ahk`. Verified on Windows. Still not idempotent: the Kinto zip is re-downloaded, re-extracted and re-copied on every run (about 9 `changed`).
- **XFCE workspace shortcuts** were deleted and recreated by two scripts on every run, and the deletion script's PCRE-style pattern (`(?:…)`, `.*?`) made `grep -E` print `? at start of expression`, which its task counted as a change. `files/scripts/sync_xfce4_workspace_switch_shortcuts.sh` now removes only stale workspace bindings and sets only missing or wrong ones, printing a line per change (`--check` reports without changing; `LMC_XFCONF_CHANNEL` points it at a scratch channel for testing). Verified in WSL2's XFCE session on a scratch channel and against the live settings (no changes). Relatedly, a `<Super>l` existence check used `ignore_errors`, so its expected non-zero exit printed a red `fatal: ... ...ignoring` on every run; existence checks use `failed_when: false`.
- **`file: state=touch`** (`.minttyrc`) always updates timestamps. Add `access_time: preserve` and `modification_time: preserve`. Verified on Windows.
- **SSH key comparison:** GitHub's `user/keys` returns `<type> <base64>` without the comment, so compare only the first two fields of the local `.pub`. Verified the comparison in WSL2.
- **`stow --adopt`** had `changed_when: true`. `stow -v` prints `MV:`/`LINK:`/`UNLINK:` lines (stderr) only when it acts. Verified in a sandbox in WSL2.
- **`install_lazyvim`'s Windows MINTTY font block** was nested inside the macOS-only block, so it never ran. It now runs on Windows.
