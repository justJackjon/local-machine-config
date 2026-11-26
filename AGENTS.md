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
│       ├── install_pnpm_global_packages.yml # Idempotent pnpm global installs/updates (all platforms)
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

On Windows, Ansible runs inside MSYS2. To run commands from PowerShell:

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
- Installs latest Neovim release.
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

### 4. Preserving Comments & Rationale
- Existing tasks contain critical `# NOTE:` comments explaining why certain workarounds exist (e.g., WSL world-writable mounts, Cloudflare blocks on AutoHotkey Scoop manifests, nvm-windows 2.x proxy shims shadowing Scoop's on PATH).
- **Never remove or overwrite `# NOTE:` comments** unless the workaround is being intentionally retired.

### 5. Verification Checklist for Agents
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
- **Diagnose quickly:** `pacman -Si mingw-w64-x86_64-<name>` per package. `unzip` was previously only present transitively and is now listed explicitly (needed by `unarchive` for the Kinto zip). Windows-only.

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
- **`regedit.exe` always prompts for elevation**, which failed an unattended run (`The operation was canceled by the user`). Kinto's `theme_ubuntu.reg` only writes `HKCU\Console`, so it's imported with `reg.exe import`. Verified on Windows.

### Debugging WSL runs from the Windows host
- An agent on the Windows host can read and run things in WSL directly, without being installed there: `wsl -d Ubuntu -- bash -lc "..."`. `run-playbook.sh` always appends Ansible's output to `${TMPDIR:-/tmp}/local-machine-config-ansible.log` (override with `ANSIBLE_LOG_PATH`), so `tail -200 /tmp/local-machine-config-ansible.log` shows the latest run. `/tmp/local-machine-config-install.log` is written only by `install.sh`. WSL can see the Windows checkout at `/mnt/c/Users/<user>/Repos/local-machine-config`, so you can test edits before pushing them.
- `sudo` in WSL needs the user's password, so an agent can't do a full run. Test a change with a small playbook that skips `become`, then have the user re-run `./run-playbook.sh` in WSL.

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
- **`file: state=touch`** (`.minttyrc`) always updates timestamps. Add `access_time: preserve` and `modification_time: preserve`. Verified on Windows.
- **SSH key comparison:** GitHub's `user/keys` returns `<type> <base64>` without the comment, so compare only the first two fields of the local `.pub`. Verified the comparison in WSL2.
- **`stow --adopt`** had `changed_when: true`. `stow -v` prints `MV:`/`LINK:`/`UNLINK:` lines (stderr) only when it acts. Verified in a sandbox in WSL2.
- **`install_lazyvim`'s Windows MINTTY font block** was nested inside the macOS-only block, so it never ran. It now runs on Windows.
