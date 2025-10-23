# local-machine-config

This repository contains Ansible playbooks and roles for configuring a local development machine. The goal is to automate the setup of essential tools, applications, and system settings across different operating systems (primarily Debian-based Linux, macOS, and Windows with MSYS2).

## Table of Contents

*   [Features](#features)
*   [Prerequisites](#prerequisites)
*   [Setup](#setup)
*   [Usage](#usage)
*   [Roles Overview](#roles-overview)
*   [Dependencies (Installed Software)](#dependencies-installed-software)
*   [TODO](#todo)

## Features

*   **Cross-Platform Configuration:** Supports Debian-based Linux, macOS, and Windows (via MSYS2/Chocolatey).
*   **Base Package Installation:** Installs fundamental development tools and utilities.
*   **Shell Configuration:** Sets up default shell and Ansible tab completion.
*   **Keyboard Customization:** Configures custom keyboard mappings and workspace switching shortcuts.
*   **Browser Installation:** Installs a web browser (Chrome or Firefox).
*   **Neovim & LazyVim Setup:** Automates the installation and configuration of Neovim with the LazyVim distribution, including a Nerd Font.
*   **Kinto.sh Integration:** Installs and configures Kinto.sh for improved keyboard experience on Linux.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

*   **Git:** For cloning this repository.
*   **Python 3:** Ansible requires Python to run.
*   **Ansible:** The automation engine used by this project.

### Installing Ansible

**Linux (Debian/Ubuntu):**

```bash
sudo apt update
sudo apt install python3-pip
pip install --user ansible
```

**macOS:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ansible
```

**Windows (with WSL or MSYS2):**

It is recommended to use Windows Subsystem for Linux (WSL) or MSYS2 for running Ansible on Windows. Follow the Linux instructions within your WSL environment or MSYS2 terminal.

## Setup

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/local-machine-config.git
    cd local-machine-config
    ```

2.  **Verify Ansible Installation:**

    ```bash
    ansible --version
    ```

## Usage

The main playbook `setup_ansible_controller.yml` will configure your local machine by running a series of roles.

To run the main setup playbook:

```bash
ansible-playbook -i hosts playbooks/setup_ansible_controller.yml --ask-become-pass
```

*   `ansible-playbook`: The command to execute an Ansible playbook.
*   `-i hosts`: Specifies the inventory file (in this case, `hosts` which defines `localhost`).
*   `playbooks/setup_ansible_controller.yml`: The path to the main playbook.
*   `--ask-become-pass`: Prompts for your sudo password if any tasks require elevated privileges (e.g., installing packages).

## Roles Overview

This repository is structured into several Ansible roles, each responsible for a specific aspect of machine configuration.

*   **`common/`**: Contains common tasks used across playbooks, primarily for setting up Ansible facts related to the operating system and architecture.
    *   `set_os_facts.yml`: Determines the operating system family (e.g., Debian, RedHat, macOS, Windows).
    *   `set_python_interpreter.yml`: Configures the Python interpreter for Ansible.
    *   `set_sys_architecture_facts.yml`: Identifies the system's architecture (e.g., amd64, arm64).

*   **`configure_keyboard/`**:
    *   Applies custom keyboard mappings (e.g., for specific Chromebook layouts).
    *   Configures general keyboard shortcuts for XFCE desktop.
    *   Sets up workspace switching shortcuts for XFCE and macOS.
    *   Installs and configures [Kinto.sh](https://kinto.sh/) on Linux for macOS-like keyboard shortcuts.

*   **`configure_shell/`**:
    *   Changes the default shell on macOS to Homebrew's Bash.
    *   Enables tab completion for Ansible CLI commands.

*   **`install_base_packages/`**:
    *   Installs essential packages like `python3-pip` and `bash-completion` on Debian-based systems.
    *   Installs equivalent packages via Homebrew on macOS and Pacman on Windows (MSYS2).

*   **`install_browser/`**:
    *   Installs Google Chrome on Debian-based AMD64 systems.
    *   Installs Firefox on Debian-based ARM64 systems (as Chrome is not available).

*   **`install_lazyvim/`**:
    *   Installs Neovim.
    *   Clones and sets up [LazyVim](https://www.lazyvim.org/) (a Neovim distribution).
    *   Installs a [Nerd Font](https://www.nerdfonts.com/) (Cascadia Code) and configures terminal emulators (XFCE Terminal, macOS Terminal, Mintty on Windows) to use it.

*   **`stow_dotfiles/`**:
    *   Manages dotfiles by cloning my personal `.dotfiles` repository from GitHub.
    *   Uses GNU Stow to symlink the dotfiles into my home directory.

*   **`install_spacevim/`**:
    *   **Note:** This role is being deprecated and replaced by `install_lazyvim`.

## Dependencies (Installed Software)

The playbooks in this repository will install and configure the following software on your system:

*   **Ansible** (Prerequisite, but also ensures its setup)
*   **Neovim**
*   **LazyVim** (Neovim distribution)
*   **Nerd Fonts** (Cascadia Code)
*   **Google Chrome** or **Mozilla Firefox** (depending on OS/architecture)
*   **Kinto.sh** (Linux only)
*   **Homebrew** (macOS)
*   **Chocolatey** (Windows)
*   **MSYS2** (Windows)
*   **Python 3 & pip**
*   **Bash & Bash Completion**
*   **argcomplete** (for Ansible tab completion)

## TODO:
- Add new nvim role to replace SpaceVim role
- Install tmux
- Manage keys
- Ensure Node LTS is installed (all operating systems)
- On XFCE desktop, add 'Workspace Switcher' plugin to top panel