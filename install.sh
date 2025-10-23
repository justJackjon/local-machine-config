#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail

# Function to print messages
info() {
    printf "\033[0;35mINFO: %s\033[0m\n" "$1"
}

# Function to print note messages
note() {
    printf "\033[0;36mNOTE: %s\033[0m\n" "$1"
}

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     os="Linux";;
    Darwin*)    os="macOS";;
    CYGWIN*)    os="Windows";;
    MINGW*)     os="Windows";;
    *)          os="UNKNOWN:${OS}"
esac

info "Detected OS: ${os}"

if [ "$os" == "Linux" ]; then
    info "Running on Linux"
    note "This script is designed for Debian-based distributions (e.g., Ubuntu, Mint) using apt-get."
    # Install dependencies
    info "Updating package list..."
    sudo apt-get update
    info "Installing dependencies (git, python3, ansible)..."
    sudo apt-get install -y git python3 python3-pip python3-venv
    python3 -m pip install --user pipx
    pipx ensurepath
    pipx install ansible
elif [ "$os" == "macOS" ]; then
    info "Running on macOS"
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
        info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Install dependencies
    info "Updating Homebrew..."
    brew update
    info "Installing dependencies (git, ansible)..."
    brew install git ansible
elif [ "$os" == "Windows" ]; then
    info "Running on Windows"
    info "Please ensure you are running this script in a Git Bash or similar shell."
    info "Installing dependencies (git, ansible) via Chocolatey..."
    # Install Chocolatey if not installed
    if ! command -v choco &> /dev/null; then
        info "Chocolatey not found. Please install it first."
        info "See https://chocolatey.org/install"
        exit 1
    fi
    choco install git ansible -y
else
    info "Unsupported OS: ${os}"
    exit 1
fi

# Clone repository
if [ "$os" == "macOS" ] || [ "$os" == "Linux" ]; then
    REPO_DIR="$HOME/Repos"
else
    REPO_DIR="$HOME/repos"
fi

info "Cloning repository to ${REPO_DIR}/local-machine-config..."
mkdir -p "${REPO_DIR}"
git clone https://github.com/justjackjon/local-machine-config.git "${REPO_DIR}/local-machine-config" || {
    info "Repository already cloned. Pulling latest changes."
    cd "${REPO_DIR}/local-machine-config"
    git stash --include-untracked || true;
    git pull;
    git stash pop || true;
}

# Execute playbook
info "Executing Ansible playbook..."
cd "${REPO_DIR}/local-machine-config"
ansible-playbook -i hosts playbooks/setup_ansible_controller.yml --ask-become-pass

info "Setup complete!"
