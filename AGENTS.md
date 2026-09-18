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
│       ├── install_scoop_package.yml    # Robust Windows Scoop installer & soft-repair
│       ├── manage_ssh_config_entry.yml  # Idempotent ~/.ssh/config blockinfile manager
│       ├── set_os_facts.yml             # Discovers is_debian_family, is_mac, is_windows, is_wsl
│       ├── set_python_interpreter.yml   # Resolves Python interpreter & venv per platform
│       └── set_sys_architecture_facts.yml # Discovers is_amd64 and is_arm64
├── playbooks/
│   └── setup_ansible_controller.yml     # Master playbook orchestrating pre_tasks, roles, post_tasks
├── roles/
│   ├── configure_git/        # GPG & SSH key generation, GitHub registration, gitconfig
│   ├── configure_keyboard/   # Keyboard maps, XFCE & macOS workspace shortcuts, Kinto.sh/AHK
│   ├── configure_mcp_servers/# MCP server configs (Semgrep, Gemini CLI GitHub MCP extension)
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
| **MCP Servers** | Semgrep + GitHub MCP | Semgrep + GitHub MCP | Semgrep (MinGW/pipx) + GitHub MCP | Semgrep + GitHub MCP |
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

# Target specific tags (e.g. MCP servers or Git configuration)
./run-playbook.sh --tags "configure_mcp_servers"
./run-playbook.sh --tags "configure_git"
./run-playbook.sh --tags "install_lazyvim"

# Dry run / check mode
./run-playbook.sh --check
```

### Running on Windows from PowerShell

On Windows, Ansible runs inside MSYS2. To run commands from PowerShell:

```powershell
# Using the Scoop-installed MSYS2 bash:
& "$env:USERPROFILE\scoop\apps\msys2\current\usr\bin\bash.exe" -lc "cd /c/Users/JJB/Repos/local-machine-config && ./run-playbook.sh --syntax-check"

# To execute a full run:
& "$env:USERPROFILE\scoop\apps\msys2\current\usr\bin\bash.exe" -lc "cd /c/Users/JJB/Repos/local-machine-config && ./run-playbook.sh"
```

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
- **Windows:** Pacman packages in MSYS2, Scoop packages (`nvm`, `gh`, `gnupg`, `neovim`, `lazygit`, `alacritty`, `cascadiacode-nf`, `fzf`, `ripgrep`, `fd`, `perl`, `pnpm`, `starship`), removes conflicting Node installations from `C:\Program Files\nodejs`, installs AutoHotkey v1.1 via GitHub releases.
- **All platforms:** Installs the Rafter CLI (`@rafter-security/cli`, exposing `rafter`) globally via pnpm — the local command-safety layer invoked by AI agent guard hooks.

### `install_docker`
- **Linux/WSL2:** Installs Docker Engine (`docker-ce`, `docker-ce-cli`, `containerd.io`, the Buildx and Compose plugins) from Docker's apt repository, enables and starts the `docker` service when systemd is available, and adds the current user to the `docker` group.
- **macOS:** Installs Docker Desktop via the Homebrew cask. First launch and license acceptance remain manual.
- **Windows:** Not installed — Docker runs inside WSL2 instead.

### `install_lazyvim`
- Installs latest Neovim release.
- Backs up any pre-existing Neovim configurations (`~/.config/nvim` or `%LOCALAPPDATA%\nvim`) with a timestamped suffix.
- Clones `https://github.com/LazyVim/starter` and removes `.git`.
- Installs Cascadia Code Nerd Font and configures the relevant terminal emulator.

### `stow_dotfiles`
- Clones `https://github.com/justJackjon/.dotfiles.git` into `~/.dotfiles`.
- Safely stows using `stow */ --adopt` followed immediately by `git restore .` to guarantee local symlinks point to the version-controlled dotfiles without corrupting the dotfiles repository.

### `configure_git`
- Manages SSH key (`ed25519` at `~/.ssh/ansible-managed/github/id_rsa`). Prompts for passphrase on creation.
- Manages GPG key (RSA 4096). Prompts for passphrase on creation.
- Registers public keys with GitHub via `gh ssh-key add` and `gh gpg-key add`.
- Sets global `user.name` ("Jackjon Butcher"), `user.email` ("jackjon@justjackjon.dev"), `commit.gpgsign=true`, and signing key.
- Switches git remote URL from HTTPS to SSH (`git@github.com:justjackjon/local-machine-config.git`).

### `configure_mcp_servers`
- Installs Semgrep (`pipx` on Linux/Windows, `brew` on macOS).
- Configures Semgrep MCP server in `~/.gemini/settings.json` using `jq`.
- Installs the GitHub MCP Extension using `@google/gemini-cli` via `pnpm dlx` if `GITHUB_MCP_PAT` is present in `~/.gemini/.env`.

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
- `:bug:   (configure_mcp_servers): Fix idempotency in settings update`
- `:sparkles:   (roles): Add pinentry for gpg keys on macos`
- `:wrench:   (playbooks): Update python interpreter facts`
- `:memo:   (docs): Update AGENTS.md with execution guidelines`

### 4. Preserving Comments & Rationale
- Existing tasks contain critical `# NOTE:` comments explaining why certain workarounds exist (e.g., WSL world-writable mounts, Cloudflare blocks on AutoHotkey Scoop manifests, `ruamel.yaml.clib` incompatibilities with Python 3.14).
- **Never remove or overwrite `# NOTE:` comments** unless the workaround is being intentionally retired.

### 5. Verification Checklist for Agents
Before finishing any modification in this repository:
1. Run `./run-playbook.sh --syntax-check` to verify YAML validity and syntax.
2. If working on a specific role, verify changes with the corresponding tag (e.g. `--tags "configure_mcp_servers"`).
3. Ensure `.gitattributes` line endings are respected (LF for Linux/macOS/Ansible files, CRLF for PowerShell).
4. Run `git status` to verify no unexpected files or temporary artifacts remain.
