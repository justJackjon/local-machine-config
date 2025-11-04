# Windows & WSL2 Keyboard Remapping Plan

## 1. Executive Summary

This document outlines the correct approach for achieving macOS-style keyboard shortcuts on a Windows host, specifically for use with WSL2. Unlike native Linux environments, the default WSL2 kernel **does not include the `uinput` kernel module**. This fundamental limitation prevents Linux-native key remapping tools like `xkeysnail`, `keyszer`, and `keyd` from working, as they all depend on `uinput` to create virtual input devices.

The correct and most robust solution is to perform all key remapping on the **Windows host**. Windows-level remapping tools intercept keyboard input before it is passed to the WSL2 guest environment, ensuring that the desired shortcuts work seamlessly across all applications, including both native Windows apps and Linux GUI apps running via WSLg.

This document details two viable, Windows-host-based solutions.

## 2. The `uinput` Problem in WSL2

-   **Root Cause**: The default kernel provided by Microsoft for WSL2 is not compiled with the `uinput` module enabled. This is a known issue and has been raised with the WSL team (e.g., [https://github.com/microsoft/WSL/issues/11270](https://github.com/microsoft/WSL/issues/11270)).
-   **Impact**: Any tool that requires creating a virtual keyboard or mouse via `/dev/uinput` will fail to run inside WSL2. This includes the entire category of modern Linux key remappers.
-   **Conclusion**: Attempts to solve this problem from within the WSL2 guest environment are futile without a custom-compiled WSL kernel. The solution must be applied on the Windows host.

## 3. Solution 1: PowerToys Keyboard Manager (Recommended)

Microsoft's own PowerToys suite includes a **Keyboard Manager** utility that provides a user-friendly and powerful way to remap keys and shortcuts system-wide.

### 3.1. Automation via `default.json`

While PowerToys is a GUI application, its Keyboard Manager configuration can be automated. The settings are stored in a simple JSON file, which can be created and managed by an Ansible playbook.

-   **Configuration File Path**: `%LOCALAPPDATA%\Microsoft\PowerToys\Keyboard Manager\default.json`
-   **Automation Strategy**: An Ansible playbook can be created to place a pre-configured `default.json` file at this location, effectively applying a complex set of keymaps in a single, idempotent step.

### 3.2. Implementation Plan for a Future Agent

A future agent tasked with automating this should:

1.  **Create a New Ansible Role**: Create a new role, such as `configure_powertoys`, that will specifically target the Windows host.
2.  **Add PowerToys Installation**: Add a task to the role to install Microsoft PowerToys (e.g., using the `winget` package manager).
    ```yaml
    - name: Install Microsoft PowerToys
      win_winget:
        name: Microsoft.PowerToys
        state: present
    ```
3.  **Deploy the `default.json` Configuration**: Add a task to copy the desired configuration file into the correct location. The JSON content below, based on the community-provided Gist, is a great starting point for macOS-style shortcuts.
    *   Use the `win_template` or `win_copy` module.
    *   The path must be constructed using Windows environment variables. The `ansible_env.LOCALAPPDATA` fact can be used for this.
    ```yaml
    - name: Configure PowerToys Keyboard Manager
      win_copy:
        dest: "{{ ansible_env.LOCALAPPDATA }}\Microsoft\PowerToys\Keyboard Manager\default.json"
        content: |-
          {
            "remapKeys": {
              "inProcess": [
                {
                  "originalKeys": "164",
                  "newRemapKeys": "162"
                },
                {
                  "originalKeys": "91",
                  "newRemapKeys": "164"
                },
                {
                  "originalKeys": "162",
                  "newRemapKeys": "91"
                }
              ]
            },
            "remapKeysToText": {
              "inProcess": []
            },
            "remapShortcuts": {
              "global": [
                {
                  "originalKeys": "164;8",
                  "newRemapKeys": "162;8"
                }
                // ... (include all other shortcut mappings from the Gist)
              ],
              "appSpecific": []
            },
            "remapShortcutsToText": {
              "global": [],
              "appSpecific": []
            }
          }
    ```
4.  **Restart PowerToys**: Add a final task to restart the PowerToys process to ensure the new settings are loaded.

## 4. Solution 2: Kinto.sh on Windows (AHK Method)

An alternative, and potentially more "Kinto-native" approach, is to leverage the fact that the Kinto.sh project uses **AutoHotkey (AHK)** as its remapping engine on Windows, not `xkeysnail`.

### 4.1. How it Works

-   The Kinto `setup.py` script, when run on Windows, installs AutoHotkey and creates AHK scripts to perform the key remapping.
-   Because AHK operates at the Windows OS level, its remaps are system-wide and will naturally apply to all applications, including WSL2 GUI apps.

### 4.2. Implementation Plan for a Future Agent

1.  **Run Kinto Installer on Windows**: The primary task would be to execute the Kinto installation process on the Windows host. This involves running the `setup.py` script with Python for Windows.
2.  **Automation**: This process can be automated within an Ansible role targeting the Windows host.
    *   Ensure Python for Windows is installed.
    *   Clone the Kinto.sh repository.
    *   Execute the `setup.py` script, potentially using `ansible.windows.win_command` or `win_shell`.
    *   The Kinto installer itself handles the installation of AHK and the setup of the remapping scripts.

This approach may be simpler as it relies on the Kinto project's own Windows installation logic, but the PowerToys method may offer more transparency and direct control over the specific mappings.
