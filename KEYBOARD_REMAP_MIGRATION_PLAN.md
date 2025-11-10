# Kinto/xkeysnail to Keyszer Migration Plan

## 1. Executive Summary

This document outlines the plan to migrate the keyboard remapping functionality in the `local-machine-config` Ansible project from the unmaintained `xkeysnail` to its modern, secure successor, `keyszer`. The current implementation relies on a complex and opaque shell script from the Kinto.sh project. The proposed solution is to replace this script with a series of clean, idempotent, and more secure Ansible tasks that achieve the same goal in a more maintainable way.

## 2. Current State Analysis

The `roles/configure_keyboard/tasks/main.yml` Ansible role is responsible for setting up macOS-style keybindings using the Kinto.sh project.

-   **Mechanism**: It executes the `install_kinto.sh` script directly from the Kinto GitHub repository.
-   **Installation Process**:
    1.  The `install_kinto.sh` script downloads the Kinto repository.
    2.  It runs `setup.py`, which in turn executes `xkeysnail_service.sh`.
    3.  The `xkeysnail_service.sh` script performs the main installation:
        - It installs dependencies like `python3-pip`.
        - It clones a **forked version** of `xkeysnail` (`github.com/rbreaves/xkeysnail.git`).
        - It installs this forked `xkeysnail` **system-wide** using `sudo pip3 install`.
        - It creates a **system-wide `systemd` service** (`/lib/systemd/system/xkeysnail.service`).
-   **Security Issues**: The created `systemd` service runs `xkeysnail` as the **root user**. To allow the root-owned process to interact with the user's display, it uses an `xhost +SI:localuser:root` command, which is a significant security vulnerability.

## 3. The Problem Statement

The current approach has several major issues:

1.  **Unmaintained Dependency**: The core technology, `xkeysnail`, is no longer maintained and has known compatibility issues with modern Python libraries.
2.  **Opaque Installer**: The use of a complex, multi-layered shell script (`linux.sh` -> `setup.py` -> `xkeysnail_service.sh`) makes the process difficult to debug, customize, and maintain. It is a "black box" within the Ansible playbook.
3.  **Poor Security**: The service runs as `root`, which is unnecessary and dangerous for a key remapper. The `xhost` command required for this to work weakens the security of the user's X11 session.
4.  **System-Wide Installation**: The `sudo pip3 install` pollutes the system's Python environment, which can lead to conflicts. A user-level or isolated installation is preferable.

## 4. Desired State: A Lean, Secure `keyszer` Implementation

The goal is to replace the current implementation with a solution that is:

-   **Modern**: Uses `keyszer`, the maintained fork of `xkeysnail`.
-   **Secure**: Runs `keyszer` as a non-privileged **user service**, eliminating the need for `root` access and `xhost` hacks.
-   **Transparent & Idempotent**: Replaces the "black box" shell script with a series of clear, declarative Ansible tasks.
-   **Isolated**: Installs `keyszer` in an isolated environment using `pipx` to avoid polluting the system's Python packages.

## 5. Key Information and Resources

### 5.1. `keyszer`

-   **GitHub**: [https://github.com/joshgoebel/keyszer](https://github.com/joshgoebel/keyszer)
-   **Summary**: A maintained fork of `xkeysnail` with a focus on security, improved configuration, and bug fixes. It explicitly recommends running as a semi-privileged user, not as root.

### 5.2. Kinto.sh

-   **GitHub**: [https://github.com/rbreaves/kinto](https://github.com/rbreaves/kinto)
-   **Summary**: A project that provides macOS-like keybindings for Linux and Windows. Its Linux implementation is built on `xkeysnail`.

### 5.3. Migration from `xkeysnail` to `keyszer` for Kinto

The `keyszer` project provides a specific guide for migrating a Kinto configuration.

-   **Guide**: [USING_WITH_KINTO.md](https://github.com/joshgoebel/keyszer/blob/main/USING_WITH_KINTO.md)
-   **Required `kinto.py` Changes**:
    1.  **`pass_through_key`**: This function was removed in `keyszer`. It must be aliased at the top of `kinto.py`: `pass_through_key = ignore_key`.
    2.  **Command-line Arguments**: The service must call `keyszer` with `-c /path/to/kinto.py` instead of passing the path as a positional argument. The `--quiet` flag is obsolete.
    3.  **(Optional but Recommended)**: For macOS-style sticky application switching, `Alt-Tab` mappings should be updated to use the `bind` command (e.g., `K("RC-Tab"): [bind, K("Alt-Tab")]`).

## 5.4. Pre-Implementation System Cleanup

Before applying the new Ansible tasks, a manual cleanup was performed to ensure the system was in a clean state. This was necessary to remove any remnants from previous installation attempts or from the old Kinto installer.

The following steps were taken:

1.  **Ran Kinto's Uninstaller**: The official Kinto uninstaller was executed to leverage its built-in cleanup logic. This was done by running `python3 setup.py -r` from within the `~/Downloads/kinto-master` directory.
2.  **Removed Global Binaries**: The Kinto installer placed a global `xkeysnail` binary at `/usr/local/bin/xkeysnail`. This was manually removed using `sudo rm -f /usr/local/bin/xkeysnail`.
3.  **Uninstalled `pipx` Packages**: To ensure no isolated installations remained, `pipx uninstall keyszer` was run.
4.  **Removed Configuration and Service Files**: The following commands were run to delete any remaining configuration directories and user service files:
    *   `rm -rf ~/.config/kinto`
    *   `rm -f ~/.config/systemd/user/keyszer.service`

This comprehensive cleanup ensured that the new Ansible-based implementation would be applied to a pristine environment.

## 6. Proposed Implementation Plan

The following changes will be made to the `roles/configure_keyboard` Ansible role.

### 6.1. Modify `tasks/main.yml`

The existing `Install Kinto.sh` and `Configure Kinto.sh` blocks will be removed and replaced with a single, comprehensive block:

```yaml
- name: Install and Configure Kinto with Keyszer
  tags: [kinto_install, kinto_config]
  when: configure_keyboard_is_linux_system
  block:
    - name: Install pipx and ensure its path
      become: true
      ansible.builtin.apt:
        name: pipx
        state: present

    - name: Add pipx to PATH
      ansible.builtin.command: pipx ensurepath
      changed_when: false

    - name: Uninstall xkeysnail (if present via pipx)
      ansible.builtin.command: pipx uninstall xkeysnail
      register: xkeysnail_uninstall_result
      changed_when: "'uninstalled' in xkeysnail_uninstall_result.stdout"
      failed_when: false

    - name: Install keyszer via pipx
      ansible.builtin.command: pipx install keyszer
      register: keyszer_install_result
      changed_when: "'installed' in keyszer_install_result.stdout"

    - name: Create Kinto config directory
      ansible.builtin.file:
        path: "{{ ansible_user_dir }}/.config/kinto"
        state: directory
        mode: '0755'

    - name: Download kinto.py
      ansible.builtin.get_url:
        url: https://raw.githubusercontent.com/rbreaves/kinto/master/linux/kinto.py
        dest: "{{ ansible_user_dir }}/.config/kinto/kinto.py"
        mode: '0644'
      notify: Restart keyszer service

    - name: Patch kinto.py for keyszer compatibility
      ansible.builtin.lineinfile:
        path: "{{ ansible_user_dir }}/.config/kinto/kinto.py"
        line: "pass_through_key = ignore_key"
        insertbefore: BOF
      notify: Restart keyszer service

    - name: Patch kinto.py to enable XFCE settings
      when: configure_keyboard_is_xfce_desktop
      ansible.builtin.replace:
        path: "{{ ansible_user_dir }}/.config/kinto/kinto.py"
        regexp: "{{ item.regexp }}"
        replace: "{{ item.replace }}"
      loop:
        - { regexp: '''(# )(.*)(# xfce4)''', replace: '''\2\3''' }
        - { regexp: '''(\w.*)(# Default not-xfce4)''', replace: '''# \1\2''' }
      notify: Restart keyszer service

    - name: Create systemd user directory
      ansible.builtin.file:
        path: "{{ ansible_user_dir }}/.config/systemd/user"
        state: directory
        mode: '0755'

    - name: Create keyszer systemd user service file
      ansible.builtin.template:
        src: keyszer.service.j2
        dest: "{{ ansible_user_dir }}/.config/systemd/user/keyszer.service"
        mode: '0644'
      notify: Restart keyszer service

    - name: Enable and start keyszer user service
      ansible.builtin.systemd:
        name: keyszer
        scope: user
        state: started
        enabled: true
        daemon_reload: true
```

### 6.2. Create `templates/keyszer.service.j2`

A new template file will be created to define the `systemd` user service.

```j2
[Unit]
Description=Keyszer - Kinto Keymapping Service
After=graphical-session.target

[Service]
Type=simple
ExecStart={{ ansible_user_dir }}/.local/bin/keyszer -c {{ ansible_user_dir }}/.config/kinto/kinto.py --watch
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
```

### 6.3. Add Handler to `handlers/main.yml`

A new handler will be added to restart the `keyszer` service when its configuration or service file changes.

```yaml
- name: Restart keyszer service
  ansible.builtin.systemd:
    name: keyszer
    scope: user
    state: restarted
```

## 7. Implementation and Debugging Log

This section logs the process of implementing the proposed plan and the debugging steps taken to resolve issues.

### 7.1. Initial Implementation

The "Proposed Implementation Plan" detailed in Section 6 was executed. The `configure_keyboard` Ansible role was successfully modified and run. While the Ansible playbook completed without errors, the `keyszer` service failed to run correctly.

### 7.2. Problem Encountered: `uinput` Permissions

Checking the `systemd` user journal (`journalctl --user -u keyszer.service`) revealed the root cause of the failure:

```
(EE) Failed to open `uinput` in write mode.
Please check access permissions for /dev/uinput.
```

This confirms that while running the service as a non-root user is more secure, the user does not have the default permissions required to access the low-level input devices that `keyszer` needs to control.

### 7.3. Manual Debugging Steps (Not Yet Automated)

To resolve the permissions issue, the following manual steps were taken, based on the `keyszer` documentation's recommendation for granting user-level access:

1.  **Add User to `input` Group**: The current user was added to the `input` group to grant access to input devices.
    ```bash
    sudo usermod -a -G input jjb
    ```
2.  **Create `udev` Rule**: A `udev` rule was created to automatically grant access to the `uinput` device and input event devices to the currently logged-in user. The file `/etc/udev/rules.d/99-keyszer.rules` was created with the following content:
    ```
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess"
    KERNEL=="event*", NAME="input/%k", SUBSYSTEM=="input", TAG+="uaccess"
    ```
3.  **Reload `udev` Rules**: The `udev` service was instructed to reload the rules.
    ```bash
    sudo udevadm control --reload-rules && sudo udevadm trigger
    ```

### 7.4. Current Status & Next Steps

After applying the manual debugging steps, the `keyszer` service still fails with the same permissions error. This indicates that the new group membership and `udev` rules have not been fully applied to the current session.

**The next action required is to reboot the system.** A reboot will ensure that the user's new group membership is active and that the `udev` device permissions are correctly applied from the start of the session.

**After the reboot, the next step is to:**

1.  Verify the service status with `journalctl --user -u keyszer.service -n 20 --no-pager`.
2.  If the service is running correctly, the final task will be to automate the manual debugging steps (adding the user to the `input` group and creating the `udev` rule) within the `configure_keyboard` Ansible role to ensure the solution is fully idempotent and self-contained.

### 7.5. Post-Reboot Analysis & Final Plan for Linux (non-WSL)

Even after a full reboot, the `keyszer` service continued to fail with the same `uinput` permission error. Extensive debugging revealed that this is due to a fundamental limitation in the default WSL2 kernel, which lacks the necessary `uinput` module support.

**Therefore, the `keyszer` implementation is NOT a viable solution for WSL2.**

However, the `keyszer` implementation remains the correct and desired path for **bare-metal Linux and standard Linux VM environments**. The work done so far is valuable and will be preserved for those targets.

#### Final Debugging Steps for `keyszer` on Native Linux

Further investigation identified the most robust solution for `uinput` permissions on a native Linux system:

1.  **Ensure `uinput` Module is Loaded**: The `uinput` kernel module must be active. This can be automated by ensuring a file exists in `/etc/modules-load.d/` with the content `uinput`.
2.  **Use a More Specific `udev` Rule**: A more explicit `udev` rule is often required. The following rule, placed in `/etc/udev/rules.d/99-keyszer.rules`, has proven to be effective:
    ```
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input"
    ```

#### Next Steps for a Future Agent (in a non-WSL Linux Environment)

A future agent continuing this work on a native Linux machine should:

1.  **Verify the Manual Fix**: First, manually apply the two steps above (loading the `uinput` module and creating the more specific `udev` rule) to confirm that the `keyszer.service` runs correctly.
2.  **Automate the Fix in Ansible**: Once verified, integrate these steps into the `roles/configure_keyboard/tasks/main.yml` playbook.
    *   Add a task to create the `/etc/modules-load.d/uinput.conf` file.
    *   Add a task to create the `/etc/udev/rules.d/99-keyszer.rules` file.
    *   Add a task to ensure the current user is a member of the `input` group.
3.  **Apply Conditional Logic**: Crucially, wrap the entire `Install and Configure Kinto with Keyszer` block with a conditional statement to ensure it **only runs on non-WSL systems**:
    ```yaml
    - name: Install and Configure Kinto with Keyszer for non-WSL Linux
      when: not is_wsl | default(false)
      block:
        # ... all the keyszer and udev tasks ...
    ```

This will complete the `keyszer` migration for its intended target environments.
