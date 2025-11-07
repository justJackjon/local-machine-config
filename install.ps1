# NOTE: This script is the primary installation script for setting up a Windows development environment.
#       It must be run with Administrator privileges from a native Windows PowerShell prompt.

# Function to print messages
function Write-Info {
    param([string]$Message)
    Write-Host "`e[0;35mINFO: $Message`e[0m"
}

# Function to print error messages
function Write-ErrorMsg {
    param(
        [string]$Message,
        [switch]$NoExit
    )
    Write-Host "`e[0;31mERROR: $Message`e[0m"
    if (-not $NoExit) {
        exit 1
    }
}

# Function to print warning messages
function Write-WarningMsg {
    param([string]$Message)
    Write-Host "`e[0;33m
-------------------------------------------------------------------------------------------------------------------------------------------------
  WARNING: $Message
-------------------------------------------------------------------------------------------------------------------------------------------------
`e[0m"
}

# Function to print note messages
function Write-Note {
    param([string]$Message)
    Write-Host "`e[0;36mNOTE: $Message`e[0m"
}

# Check if running on Windows
if ($PSVersionTable.OS -notlike "*Windows*") {
    Write-ErrorMsg "This script is intended to be run on Windows. Please use install.sh for Linux/macOS."
}

Write-Info "Running on Windows"

# Define repository directory
$REPO_DIR = "$env:USERPROFILE\Repos"
$LOCAL_REPO_PATH = "$REPO_DIR\local-machine-config"

function Install-LocalMachineConfig {
  try {
    # Check if Chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        # Install Chocolatey
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed."
    }

    # Check if MSYS2 is installed
    $msys2Paths = @("C:\tools\msys64", "C:\msys64")
    $msys2Installed = $false

    ForEach ($path in $msys2Paths) {
        if (Test-Path -Path $path) {
            $msys2Installed = $true
            break
        }
    }

    if (-not $msys2Installed) {
        # Install MSYS2
        choco install msys2 -y
    } else {
        Write-Host "MSYS2 is already installed."
    }

    # Check if Git for Windows is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        # Install Git for Windows
        choco install git -y
    } else {
        Write-Host "Git for Windows is already installed."
    }

    # Open MSYS2 terminal and install Ansible
    $msys2Path = if (Test-Path -Path "C:\tools\msys64") { "C:\tools\msys64" } else { "C:\msys64" }
    $msys2Shell = Join-Path -Path $msys2Path -ChildPath "usr\bin\bash.exe"

    # Check if Ansible is installed
    $ansibleCheck = & $msys2Shell -lc "command -v ansible-playbook"

    if (-not $ansibleCheck) {
        # Install Ansible
        & $msys2Shell -lc "pacman -Syu --noconfirm"
        & $msys2Shell -lc "pacman -S --noconfirm ansible"
    } else {
        Write-Host "Ansible is already installed."
    }

    Write-Info "Installing Ansible collections..."
    & $msys2Shell -lc "ansible-galaxy collection install community.general chocolatey.chocolatey ansible.windows community.crypto community.windows"

    Write-Info "Authenticating gh CLI (user interaction required)..."
    & $msys2Shell -lc "gh auth login --web --clipboard --git-protocol ssh -h github.com -s public_repo,admin:public_key,admin:gpg_key --skip-ssh-key"
    Write-Info "gh CLI authentication complete."

    # Create a shortcut to the MSYS2 terminal on the public desktop
    $shell = New-Object -COM WScript.Shell
    $shortcut = $shell.CreateShortcut("C:\Users\Public\Desktop\MSYS2 Terminal.lnk")
    $shortcut.TargetPath = Join-Path -Path $msys2Path -ChildPath "mingw64.exe"
    $shortcut.Save()

    Write-Info "Chocolatey, MSYS2, Git for Windows, and Ansible are installed. A shortcut to the MSYS2 terminal has been created on your desktop."

    # Execute playbook
    Write-Info "Executing Ansible playbook..."
    Push-Location $LOCAL_REPO_PATH
    & $msys2Shell -lc "ansible-playbook -i hosts playbooks/setup_ansible_controller.yml --ask-become-pass"
    Pop-Location

    Write-Info "`nSetup complete! Please review the output above for any errors.`n"
  } catch {
    Write-ErrorMsg "$($_.Exception.ToString())" -NoExit
    Write-Host ""
    Write-ErrorMsg "An error occurred during the installation process." -NoExit
    Write-ErrorMsg "Please ensure you are running this script from an elevated PowerShell prompt." -NoExit
    Write-ErrorMsg "If the error persists, please check the error message above for more details."
  }
} # End of function Install-LocalMachineConfig

# Clone repository
if (-not (Test-Path -Path $LOCAL_REPO_PATH)) {
    Write-Info "Cloning repository to $LOCAL_REPO_PATH..."
    New-Item -ItemType Directory -Force -Path $REPO_DIR | Out-Null
    git clone https://github.com/justjackjon/local-machine-config.git $LOCAL_REPO_PATH
} else {
    Write-Info "Repository already cloned. Pulling latest changes."
    Push-Location $LOCAL_REPO_PATH
    git stash --include-untracked | Out-Null
    git pull | Out-Null
    git stash pop | Out-Null
    Pop-Location
}

# Change directory to the cloned repository
Set-Location $LOCAL_REPO_PATH

# Execute the main installation function
Install-LocalMachineConfig
