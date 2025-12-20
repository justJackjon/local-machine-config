#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail

# --- Configuration ---

# Function to print messages
info() {
  printf "\033[0;35mINFO: %s\033[0m\n" "$1"
}

# --- Main Execution ---

info "Executing Ansible playbook..."

# Initialize playbook arguments
PLAYBOOK_ARGS="-i hosts playbooks/setup_ansible_controller.yml"

# Detect OS to determine the correct ansible-playbook executable path and args.
OS="$(uname -s)"
case "$OS" in
Linux* | Darwin*) 
  # On Linux/macOS, we need to ask for the sudo password for privilege escalation.
  PLAYBOOK_ARGS="$PLAYBOOK_ARGS --ask-become-pass"

  # On Linux, pipx installs to a path that may not be in the current shell's PATH.
  if [ "$OS" == "Linux" ]; then
    ANSIBLE_EXECUTABLE="$HOME/.local/bin/ansible-playbook"
    info "Linux OS detected. Using explicit path for Ansible: $ANSIBLE_EXECUTABLE"
  else
    # On macOS, assume 'ansible-playbook' is in the PATH.
    ANSIBLE_EXECUTABLE="ansible-playbook"
  fi
  ;;
*)
  # On other systems (like MSYS2 on Windows), assume standard path.
  ANSIBLE_EXECUTABLE="ansible-playbook"
  ;;
esac

# Prepare the base command
CMD="$ANSIBLE_EXECUTABLE $PLAYBOOK_ARGS"

# NOTE: In WSL, the mounted filesystem can be world-writable, causing Ansible to ignore
#       the local ansible.cfg for security reasons. This leads to "role not found"
#       errors. To fix this, we explicitly tell Ansible where to find its config.
#       We detect WSL by checking the kernel release name, which is more reliable.
if [[ "$(uname -r)" == *[mM]icrosoft* ]] || [[ "$(uname -r)" == *[wW][sS][lL]* ]]; then
  info "WSL detected. Setting ANSIBLE_CONFIG to ensure roles are found."
  CMD="ANSIBLE_CONFIG=./ansible.cfg $CMD"
fi

# Execute the final command, passing along any extra arguments provided to the script
# This allows users to add flags like --syntax-check, --list-tasks, etc.
info "Running command: $CMD $@"
eval "$CMD $@"