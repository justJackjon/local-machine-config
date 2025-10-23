# local-machine-config

This repository contains Ansible playbooks and roles for configuring my local development machine. The goal is to automate the setup of essential tools, applications, and system settings across different operating systems (primarily Debian-based Linux, macOS, and Windows with MSYS2).

## Installation

This project includes a cross-platform installation script to automate the setup process. The script will:

- Detect the current operating system (Linux, macOS, or Windows).
- Install necessary dependencies (Git, Ansible, Python 3).
- Clone this repository to `~/repos` (Windows) or `~/Repos` (Linux/macOS).
- Execute the main Ansible playbook to configure the system.

To start the setup, run the following command in your terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh)"
```

> [!WARNING]
> Piping content from the internet into your shell can be dangerous. It is recommended that you inspect the script's contents before running it. You can do this by visiting the script's URL in your browser: [https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh](https://raw.githubusercontent.com/justjackjon/local-machine-config/main/install.sh)

## Features

- **Cross-Platform Configuration:** Supports Debian-based Linux, macOS, and Windows (via MSYS2/Chocolatey).
  > [!NOTE]
  > For Linux, this script is designed for Debian-based distributions (e.g., Ubuntu, Mint) using `apt-get`.
- **Base Package Installation:** Installs fundamental development tools and utilities.
- **Shell Configuration:** Sets up default shell and Ansible tab completion.
- **Keyboard Customization:** Configures custom keyboard mappings and workspace switching shortcuts.
- **Browser Installation:** Installs a web browser (Chrome or Firefox).
- **Neovim & LazyVim Setup:** Automates the installation and configuration of Neovim with the LazyVim distribution, including a Nerd Font.
- **Kinto.sh Integration:** Installs and configures Kinto.sh for improved keyboard experience on Linux.

## Roles Overview

This repository is structured into several Ansible roles, each responsible for a specific aspect of machine configuration.

- **`common/`**: Contains common tasks used across playbooks, primarily for setting up Ansible facts related to the operating system and architecture.
  - `set_os_facts.yml`: Determines the operating system family (e.g., Debian, macOS, Windows).
  - `set_python_interpreter.yml`: Configures the Python interpreter for Ansible.
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

- **`install_browser/`**:
  - Installs Google Chrome on Debian-based AMD64 systems.
  - Installs Firefox on Debian-based ARM64 systems (as Chrome is not available).

- **`install_lazyvim/`**:
  - Installs Neovim.
  - Clones and sets up [LazyVim](https://www.lazyvim.org/) (a Neovim distribution).
  - Installs a [Nerd Font](https://www.nerdfonts.com/) (Cascadia Code) and configures terminal emulators (XFCE Terminal, macOS Terminal, Mintty on Windows) to use it.

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
- **Kinto.sh** (Linux only)
- **Homebrew** (macOS)
- **Chocolatey** (Windows)
- **MSYS2** (Windows)
- **Python 3 & pip**
- **Bash & Bash Completion**
- **argcomplete** (for Ansible tab completion)

## TODO:

- Install tmux
- Manage keys
- On XFCE desktop, add 'Workspace Switcher' plugin to top panel
