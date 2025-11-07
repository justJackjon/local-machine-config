# MSYS2 Configuration Migration Plan

## 1. Objective

The primary goal is to migrate the functionality from the standalone `playbooks/configure-msys2.yml` playbook into the main `playbooks/setup_ansible_controller.yml` workflow. This involves consolidating tasks into new or existing roles, ensuring that MSYS2-specific configurations are only applied on Windows systems.

Additionally, we will analyze and consolidate the logic of the `install.sh` script and the `roles/configure_system/files/scripts/prep_win_environment.ps1` PowerShell script to create a single, streamlined setup process.

## 2. Analysis

### 2.1. `playbooks/configure-msys2.yml` Functionality

This playbook performs the following actions on a Windows machine with MSYS2:

-   **Admin Privilege Check**: Ensures the playbook is run with administrative rights.
-   **MSYS2 Configuration**:
    -   Sets `db_home: windows` in `/etc/nsswitch.conf` to make the home directory (`~`) point to the Windows user profile.
    -   Sets `MSYS2_PATH_TYPE=inherit` in `/mingw64.ini` to inherit the full Windows PATH.
-   **User Configuration Files**: Creates `.bash_profile` and `.bashrc` in the user's home directory if they don't exist.
-   **Font Installation**: Installs the "Caskaydia Cove Nerd Font" using Chocolatey.
-   **MINTTY Configuration**:
    -   Creates a `.minttyrc` file.
    -   Configures `.minttyrc` to use the installed Nerd Font.
    -   Installs the Dracula theme for MINTTY and configures `.minttyrc` to use it.
-   **Starship Prompt**: Installs Starship via `pacman` and configures `.bashrc` to initialize it.

### 2.2. Script Overlap: `install.sh` vs. `prep_win_environment.ps1`

There is significant overlap between these two scripts, particularly in bootstrapping a Windows environment.

-   **`prep_win_environment.ps1`**:
    -   Installs Chocolatey.
    -   Installs MSYS2 using Chocolatey.
    -   Installs Git for Windows using Chocolatey.
    -   Installs Ansible within the MSYS2 environment using `pacman`.
    -   Creates a desktop shortcut for the MSYS2 terminal.

-   **`install.sh`**:
    -   Detects the operating system.
    -   For Windows, it expects to be run in a Git Bash-like environment.
    -   Checks for and uses Chocolatey to install `git` and `ansible`.
    -   Installs several Ansible Galaxy collections.
    -   Handles `gh` CLI authentication.
    -   Clones the repository.
    -   Executes the main `setup_ansible_controller.yml` playbook.

The PowerShell script (`prep_win_environment.ps1`) is designed to solve the "chicken-and-egg" problem where Ansible is needed to configure the environment, but Ansible itself isn't installed. The `install.sh` script is the intended entry point for all operating systems and performs a wider range of setup tasks.

## 3. Migration and Consolidation Strategy

### 3.1. Script Consolidation

We will rename `prep_win_environment.ps1` to `install.ps1` and consolidate all Windows-specific installation logic into this PowerShell script. This addresses the "chicken and egg" problem where `install.sh` was responsible for cloning the repository, but `prep_win_environment.ps1` needed the repository to be present to execute `install.sh`.

The new `install.ps1` script will be the definitive entry point for Windows and will be responsible for:
1.  Checking for and installing Chocolatey.
2.  Using Chocolatey to install `msys2`, `git`, and `ansible`.
3.  **Cloning the `local-machine-config` repository.**
4.  Performing the Ansible Galaxy collection installations.
5.  Handling `gh` authentication.
6.  Executing the main Ansible playbook (`setup_ansible_controller.yml`).

The `install.sh` script will be modified to remove all Windows-specific logic and will only handle Linux and macOS installations.

### 3.2. Playbook and Role Migration

The functionality of `configure-msys2.yml` will be broken down and integrated into roles that are conditionally executed by `setup_ansible_controller.yml`.

-   **New Role: `configure_msys2`**
    -   This role will be created to handle the core MSYS2 configuration.
    -   It will be executed only when `ansible_facts.os_family == 'Windows'`.
    -   **Tasks**:
        -   Configure `/etc/nsswitch.conf`.
        -   Configure `/mingw64.ini`.
        -   Create `.bash_profile` and `.bashrc`.
        -   Configure `.minttyrc` (font and theme).

-   **Existing Role: `install_base_packages`**
    -   The task to install the "Caskaydia Cove Nerd Font" via Chocolatey will be moved here, under a `when: is_windows` condition. This consolidates package/font installations.

-   **Existing Role: `configure_shell`**
    -   The tasks for installing and configuring Starship will be moved here, under a `when: is_windows` condition. This keeps shell-related configuration together.

-   **New Role: `configure_theme` (or similar)**
    -   The Dracula theme installation for MINTTY will be moved into a new, dedicated role for themes, or included in the `configure_msys2` role if it's the only theme task. For simplicity, we will start by including it in `configure_msys2`.

## 4. Task Checklist

-   [x] Create a new markdown file named `MSYS2_MIGRATION_PLAN.md` with the contents of this plan.
-   [x] **Script Consolidation**:
    -   [x] The `prep_win_environment.ps1` script is crucial for bootstrapping a Windows environment from a native PowerShell prompt. It installs the necessary Unix-like environment (MSYS2/Git Bash) where `install.sh` can then be executed.
    -   [x] Modified `prep_win_environment.ps1` to automatically execute `install.sh` within the MSYS2 bash environment after initial setup.
    -   [x] Moved `prep_win_environment.ps1` to the project root.
    -   [x] Updated comments in `install.sh` (Windows section) to clarify its execution context and the role of `prep_win_environment.ps1`.
    -   [x] Updated comments in `prep_win_environment.ps1` to clearly explain its role as the initial Windows bootstrap script and its automation of `install.sh` execution.
    -   [x] Updated `README.md` to include specific instructions for Windows, detailing the role of `prep_win_environment.ps1` and how it automates the execution of `install.sh`, and separate instructions for Linux and macOS.
    -   [x] Updated `README.md` to provide a single PowerShell command for direct execution of `prep_win_environment.ps1` from GitHub, improving UX feature parity.
-   [ ] **Role Creation and Migration**:
    -   [x] Create a new role: `roles/configure_msys2`.
    -   [x] Move MSYS2, `.bashrc`, `.minttyrc`, and Dracula theme configuration tasks from `playbooks/configure-msys2.yml` to the new `roles/configure_msys2/tasks/main.yml`.
    -   [x] Move the Nerd Font installation task to `roles/install_base_packages/tasks/main.yml` with a Windows condition.
    -   [x] Move the Starship installation and configuration tasks to `roles/configure_shell/tasks/main.yml` with a Windows condition.
-   [ ] **Update Main Playbook**:
    -   [x] Add the new `configure_msys2` role to `playbooks/setup_ansible_controller.yml`, ensuring it runs only on Windows.
    -   [x] Delete the now-empty `playbooks/configure-msys2.yml` file.
-   [ ] **Verification**:
    -   [ ] Review all changes to ensure they are idempotent and follow project conventions.
    -   [ ] (Manual) Test the updated `install.sh` script on a clean Windows environment.
    -   [ ] (Manual) Run the `setup_ansible_controller.yml` playbook on a configured Windows environment to verify the changes.
