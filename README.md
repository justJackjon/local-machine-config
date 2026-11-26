# local-machine-config

This repository contains Ansible playbooks and roles for configuring my local development machine. The goal is to automate the setup of essential tools, applications, and system settings across different operating systems (primarily Debian-based Linux, macOS, and Windows with MSYS2).

## Installation

This project includes a cross-platform installation script to automate the setup process. The script will:

- Detect the current operating system (Linux, macOS, or Windows).
- Install necessary dependencies (Git, Ansible, Python 3).
- Clone this repository to `~/repos` (Windows) or `~/Repos` (Linux/macOS).
- Execute the main Ansible playbook to configure the system.

### Windows Installation

To start the setup on Windows, run the following command from an **elevated PowerShell prompt**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.ps1'))
```

> [!NOTE]
> The script will pause at the end (or upon failure) to allow you to review the output. Full logs are also saved to `$env:TEMP\local-machine-config-install.log`, and Ansible's playbook output is saved to `$env:TEMP\local-machine-config-ansible.log`.

> [!WARNING]
> Piping content from the internet into your shell can be dangerous. It is recommended that you inspect the script's contents before running it. You can do this by visiting the script's URL in your browser: [https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.ps1](https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.ps1)

### New Windows Machine (with WSL2)

The playbook does not install WSL itself. On a new Windows machine:

1. Run the Windows installation above on the Windows host.
2. Install WSL2 (`wsl --install -d Ubuntu` from an elevated prompt), reboot, launch Ubuntu once to create your user, then run the Linux installation below inside WSL. This sets up an XFCE desktop reachable over RDP.
3. Connect to that desktop with Remote Desktop (`mstsc.exe`, using the WSL IP the playbook prints) and run `./run-playbook.sh` again from a terminal **inside** the XFCE session, so the XFCE keyboard and workspace settings are applied.

See `AGENTS.md` for details and known pitfalls.

### Linux and macOS Installation

To start the setup on Linux or macOS, run the following command in your terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh)"
```

> [!NOTE]
> The script will pause at the end (or upon failure) to allow you to review the output. Full logs are also saved to `/tmp/local-machine-config-install.log`, and every `./run-playbook.sh` run appends Ansible's output to `/tmp/local-machine-config-ansible.log`.

> [!WARNING]
> Piping content from the internet into your shell can be dangerous. It is recommended that you inspect the script's contents before running it. You can do this by visiting the script's URL in your browser: [https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh](https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh)

## Manual Execution

After cloning the repository, the standard way to run the playbook is by using the `run-playbook.sh` wrapper script. This script handles environment-specific issues, providing a consistent experience across all platforms.

```bash
./run-playbook.sh
```

You can also pass extra arguments to the `ansible-playbook` command, such as `--syntax-check` or `--list-tasks`:

```bash
./run-playbook.sh --syntax-check
```

> [!NOTE]
> **Why is this script needed?**
> When running inside WSL, Ansible may ignore the local `ansible.cfg` file due to the "world-writable" permissions of mounted Windows drives. This causes Ansible to fail when it cannot find the roles defined in `roles_path`. The `run-playbook.sh` script automatically detects this WSL environment and forces Ansible to use the correct configuration file, ensuring the playbook runs correctly everywhere.

## Supply-Chain Safety

This repository installs a lot of third-party software, so it limits how much a single malicious or broken release can reach:

- **Release-age cooldown:** packages and releases are installed only once they are at least **7 days** old, giving the community time to find and pull a bad release. This covers pip, pipx, npm, pnpm (including `pnpm self-update`), GitHub release downloads (Neovim, lazygit, fzf, Starship, nvm-windows) and the Alacritty crate. To take an urgent fix sooner, override it for one run:

  ```bash
  ./run-playbook.sh -e supply_chain_min_release_age_days=0
  ```

- **Pinned, checksummed downloads:** files that used to come from a branch (`master`, `HEAD`) are fetched by commit or release tag, with a SHA-256 kept in this repository or published by GitHub for the release asset.
- **Downloaded, then run:** vendor install scripts are saved to a file and run from there, never piped from the network straight into a shell. Claude Code is installed from its `stable` channel.
- **Locked builds:** Alacritty is built with `cargo install --locked`, so its dependencies are the versions Alacritty published, not whatever is newest at build time.

Not covered by the cooldown: apt, Homebrew, Scoop and MSYS2's pacman (signed or checksummed by their maintainers, with no release-age setting), Node.js LTS from nvm, the Rust toolchain from rustup, and Google Chrome's `.deb` (later updates come from Google's signed apt repository). See `AGENTS.md` for the details.

### Contributing

Work on a short-lived branch named `<type>/<short-kebab-description>` (for example `feat/supply-chain-hardening` or `fix/wsl-installation`), and merge it into `main` with a pull request. `main` requires pull requests and signed commits. Commit messages follow the Gitmoji + scope format described in `AGENTS.md`.

## Post-Installation

After the main playbook has finished, you will need to start a new shell session (or run `source ~/.bashrc`) for all changes to take effect. This is especially important for interacting with services like GitHub, as the `ssh-agent` will only be started in new shell sessions.

## Features

- **Cross-Platform Configuration:** Supports Debian-based Linux, macOS, and Windows (via MSYS2/Chocolatey and WSL).
  > [!NOTE]
  > For Linux, this script is designed for Debian-based distributions (e.g., Ubuntu, Mint) using `apt-get`.
- **Base Package Installation:** Installs fundamental development tools and utilities.
- **Shell Configuration:** Sets up default shell, Starship prompt (Linux), and Ansible tab completion.
- **Keyboard Customization:** Configures custom keyboard mappings and workspace switching shortcuts.
- **Browser Installation:** Installs a web browser (Chrome or Firefox).
- **Docker Installation:** Installs Docker Engine on Linux/WSL2 and Docker Desktop on macOS (Docker runs inside WSL2 on Windows hosts).
- **Neovim & LazyVim Setup:** Automates the installation and configuration of Neovim with the LazyVim distribution, including a Nerd Font.
- **Kinto.sh Integration:** Installs and configures Kinto.sh for improved keyboard experience on Linux.
- **WSL GUI Setup:** Automates the installation and configuration of XFCE and XRDP for a graphical desktop environment within WSL.

## Roles Overview

This repository is structured into several Ansible roles, each responsible for a specific aspect of machine configuration.

- **`common/`**: Contains common tasks used across playbooks, primarily for setting up Ansible facts related to the operating system and architecture.
  - `set_os_facts.yml`: Determines the operating system family (e.g., Debian, macOS, Windows) and detects if running within a WSL environment, setting the `is_wsl` fact.
  - `set_python_interpreter.yml`: Configures the Python interpreter for Ansible. On Windows, it handles the complex logic of selecting the MSYS2 interpreter for Ansible execution (to support POSIX requirements like the `grp` module) while optionally setting up a MinGW64-based virtual environment for development tools.
  - `set_sys_architecture_facts.yml`: Identifies the system's architecture (e.g., amd64, arm64).

- **`configure_keyboard/`**:
  - Applies custom keyboard mappings (e.g., for specific Chromebook layouts).
  - Configures general keyboard shortcuts for XFCE desktop.
  - Sets up workspace switching shortcuts for XFCE and macOS.
  - Installs and configures [Kinto.sh](https://kinto.sh/) on Linux for macOS-like keyboard shortcuts.

- **`configure_shell/`**:
  - Changes the default shell on macOS to Homebrew's Bash.
  - Enables tab completion for Ansible CLI commands.

- **`install_base_packages/`**:
  - Installs essential packages like `python3-pip` and `bash-completion` on Debian-based systems.
  - Installs equivalent packages via Homebrew on macOS and Pacman on Windows (MSYS2).
  - Installs the Rafter CLI (`@rafter-security/cli`) globally via pnpm on all platforms for agent command-safety guardrails.

- **`install_browser/`**:
  - Installs Google Chrome on Debian-based AMD64 systems.
  - Installs Firefox on Debian-based ARM64 systems (as Chrome is not available).

- **`install_docker/`**:
  - Installs Docker Engine (`docker-ce`) on Debian-based Linux and WSL2, enables and starts the `docker` service, and adds the current user to the `docker` group.
  - Installs Docker Desktop via the Homebrew cask on macOS.
  - Does not install anything on Windows — Docker runs inside WSL2 instead.

- **`install_lazyvim/`**:
  - Installs Neovim.
  - Clones and sets up [LazyVim](https://www.lazyvim.org/) (a Neovim distribution).
  - Installs a [Nerd Font](https://www.nerdfonts.com/) (Cascadia Code) and configures terminal emulators (XFCE Terminal, macOS Terminal, Mintty on Windows) to use it.

- **`install_wsl_gui/`**:
  - Installs and configures XFCE (Xfce Desktop Environment) and XRDP (X.Org RDP server) for a graphical desktop experience in WSL environments.

- **`stow_dotfiles/`**:
  - Manages dotfiles by cloning my personal `.dotfiles` repository from GitHub.
  - Uses GNU Stow to symlink the dotfiles into my home directory.

- **`install_spacevim/`**:
  - **Note:** This role is being deprecated and replaced by `install_lazyvim`.

## Dependencies (Installed Software)

The playbooks in this repository will install and configure the following software on your system:

- **Ansible** (Prerequisite, but also ensures its setup)
- **Neovim**
- **LazyVim** (Neovim distribution)
- **Nerd Fonts** (Cascadia Code)
- **Google Chrome** or **Mozilla Firefox** (depending on OS/architecture)
- **Docker Engine** (Linux/WSL2) or **Docker Desktop** (macOS)
- **XFCE** (Xfce Desktop Environment)
- **XRDP** (X.Org RDP server)
- **Kinto.sh** (Linux only)
- **Homebrew** (macOS)
- **Chocolatey** (Windows)
- **MSYS2** (Windows)
- **Python 3 & pip**
- **Bash & Bash Completion**
- **Starship** (Linux only)
- **argcomplete** (for Ansible tab completion)
- **Rafter CLI** (`@rafter-security/cli`, agent command-safety guardrails)

## TODO:

- Install tmux
- On XFCE desktop, add 'Workspace Switcher' plugin to top panel
- Create a common clipboard API (e.g., `pbcopy`/`pbpaste` wrappers) to abstract away platform-specific commands like `xclip`, `pbcopy`, and `/dev/clipboard`.
- Apply the supply-chain cooldown to the remaining sources: Ansible Galaxy collections (`install.sh` installs the newest from Galaxy, though the `ansible` package already bundles them), Scoop, and the fzf binary that fzf's installer downloads.
- Add CI (ansible-lint and a secret scanner such as gitleaks, with actions pinned by commit SHA).
- Refactor to set fully qualified executable paths (e.g., for scoop, nvm, pnpm) as global facts in an early `pre_tasks` block. This will provide a central, commented location to manage paths and solve the "first-run PATH issue" more cleanly than repeating logic in each role.
