#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail

# Function to print messages
info() {
  printf "\033[0;35mINFO: %s\033[0m\n" "$1"
}

# Function to print error messages
error() {
  printf "\033[0;31mERROR: %s\033[0m\n" "$1" >&2
}

# Function to print warning messages
warning() {
  printf "\033[0;33m
-------------------------------------------------------------------------------------------------------------------------------------------------\n
  WARNING: %s\n
-------------------------------------------------------------------------------------------------------------------------------------------------
\033[0m\n" "$1" >&2
}

# Function to print note messages
note() {
  printf "\033[0;36mNOTE: %s\033[0m\n" "$1"
}

# Detect OS
OS="$(uname -s)"
case "$OS" in
Linux*) os="Linux" ;;
Darwin*) os="macOS" ;;
CYGWIN*) os="Windows" ;;
MINGW*) os="Windows" ;;
*) os="UNKNOWN:${OS}" ;;
esac

info "Detected OS: ${os}"

if [ "$os" == "Linux" ]; then
  info "Running on Linux"
  note "This script is designed for Debian-based distributions (e.g., Ubuntu, Mint) using apt-get."

  info "Updating package list..."
  sudo apt-get update

  info "Installing dependencies (git, python3, ansible)..."
  sudo apt-get install -y git python3 python3-pip python3-venv pipx
  pipx ensurepath
  pipx install ansible ansible-core

  info "Installing Ansible collections..."
  "$HOME/.local/bin/ansible-galaxy" collection install community.general chocolatey.chocolatey ansible.windows community.crypto

  info "Killing any running Chrome processes to ensure a clean browser session for authentication..."
  pkill -f "chrome" || true

  info "Authenticating gh CLI (user interaction required)..."
  # Check gh version for conditional flags
  GH_VERSION=$(gh --version | head -n 1 | cut -d ' ' -f 3)
  if printf '%s\n' "2.48.0" "$GH_VERSION" | sort -V -C; then
    # The gh version is 2.48.0 or higher, use --skip-ssh-key...
    gh auth login --web --git-protocol ssh -h github.com -s public_repo,write:gpg_key,admin:public_key --skip-ssh-key
  else
    # The gh version is older, --skip-ssh-key flag not available.
    # The --clipboard flag is also only available in gh 2.79.0 or higher, see: https://github.com/cli/cli/releases/tag/v2.79.0
    warning "When prompted to 'Generate a new SSH key to add to your GitHub account?', please answer 'n'. Ansible will handle SSH key generation."
    note "The --skip-ssh-key flag is not available in your gh CLI version (${GH_VERSION}). See: https://github.com/cli/cli/releases/tag/v2.48.0 for release notes."
    gh auth login --web --git-protocol ssh -h github.com -s public_repo,write:gpg_key,admin:public_key
  fi
  info "gh CLI authentication complete."

elif [ "$os" == "macOS" ]; then
  info "Running on macOS"

  if ! command -v brew &>/dev/null; then
    info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  info "Updating Homebrew..."
  brew update

  info "Installing dependencies (git, ansible)..."
  brew install git ansible-core

  info "Installing Ansible collections..."
  ansible-galaxy collection install community.general chocolatey.chocolatey ansible.windows community.crypto

  info "Authenticating gh CLI (user interaction required)..."
  gh auth login --web --clipboard --git-protocol ssh -h github.com -s public_repo,write:gpg_key,admin:public_key --skip-ssh-key
  info "gh CLI authentication complete."

elif [ "$os" == "Windows" ]; then
  info "Running on Windows"
  note "Please ensure you are running this script in a Git Bash or similar shell."

  if ! command -v choco &>/dev/null; then
    error "Chocolatey not found. Please install it first."
    info "See https://chocolatey.org/install"
    exit 1
  fi

  info "Installing dependencies (git, ansible) via Chocolatey..."
  choco install git ansible -y

  info "Installing Ansible collections..."
  ansible-galaxy collection install community.general chocolatey.chocolatey ansible.windows community.crypto

  info "Authenticating gh CLI (user interaction required)..."
  gh auth login --web --clipboard --git-protocol ssh -h github.com -s public_repo,write:gpg_key,admin:public_key --skip-ssh-key
  info "gh CLI authentication complete."
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
git clone https://github.com/justjackjon/local-machine-config.git "${REPO_DIR}/local-machine-config" 2>/dev/null || {
  info "Repository already cloned. Pulling latest changes."
  cd "${REPO_DIR}/local-machine-config"
  git stash --include-untracked >/dev/null 2>&1 || true
  git pull >/dev/null 2>&1
  git stash pop >/dev/null 2>&1 || true
}

# Execute playbook
info "Executing Ansible playbook..."
cd "${REPO_DIR}/local-machine-config"

if [ "$os" == "Linux" ]; then
  "$HOME/.local/bin/ansible-playbook" -i hosts playbooks/setup_ansible_controller.yml --ask-become-pass
else
  ansible-playbook -i hosts playbooks/setup_ansible_controller.yml --ask-become-pass
fi

info "Setup complete!"
