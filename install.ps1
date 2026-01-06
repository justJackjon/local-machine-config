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
    Write-Host ""
    Read-Host "Press Enter to exit..."
    Stop-Transcript -ErrorAction SilentlyContinue
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

# Start transcript logging to a temp file
$logFile = Join-Path -Path $env:TEMP -ChildPath "local-machine-config-install.log"
Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue
Write-Info "Running on Windows"
Write-Note "Transcript logging started. Logs will be saved to: $logFile"

# Define repository directory
$REPO_DIR = "$env:USERPROFILE\Repos"
$LOCAL_REPO_PATH = "$REPO_DIR\local-machine-config"

function Install-LocalMachineConfig {
  try {
    # Check if Scoop is installed
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
      Write-Info "Installing Scoop..."
      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
      Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    } else {
      Write-Host "Scoop is already installed."
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
      Write-Info "Installing MSYS2 via Scoop..."
      scoop install msys2
    } else {
      Write-Host "MSYS2 is already installed."
    }

    # Define MSYS2 Path
    $msys2Path = switch ($true) {
      { Test-Path -Path "C:\tools\msys64" } { "C:\tools\msys64"; break }
      { Test-Path -Path "C:\msys64" } { "C:\msys64"; break }
      default { "$env:USERPROFILE\scoop\apps\msys2\current" }
    }

    $msys2Shell = Join-Path -Path $msys2Path -ChildPath "usr\bin\bash.exe"

    # MSYS2 Initialization "Warm-up"
    Write-Info "Performing MSYS2 initialization (this may take a moment)..."
    & $msys2Shell -lc "echo 'MSYS2 shell initialized'"
    
    # Sometimes MSYS2 needs a second kick to finish creating home directories
    Start-Sleep -Seconds 2
    & $msys2Shell -lc "echo 'Environment check: ' && whoami && pwd"

    # Check if Git for Windows is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      # Install Git for Windows
      Write-Info "Installing Git for Windows via Scoop..."
      scoop install git
    } else {
      Write-Host "Git for Windows is already installed."
    }

    # Check if Ansible is installed IN MSYS2
    Write-Info "Checking for Ansible in MSYS2 environment..."
    $ansibleCheck = & $msys2Shell -lc "which ansible-playbook 2>/dev/null"

    if (-not $ansibleCheck) {
      # Install Ansible
      Write-Info "Installing Ansible in MSYS2..."
      & $msys2Shell -lc "pacman -Syu --noconfirm"
      & $msys2Shell -lc "pacman -S --noconfirm base-devel ansible"
    } else {
      Write-Host "Ansible is already installed in MSYS2."
    }

    Write-Info "Installing Ansible collections..."
    & $msys2Shell -lc "ansible-galaxy collection install community.general ansible.windows community.crypto community.windows"

    # Check if gh is installed
    $ghCheck = & $msys2Shell -lc "export PATH=/mingw64/bin:`$PATH && which gh 2>/dev/null"

    if (-not $ghCheck) {
      # Install gh
      Write-Info "Installing GitHub CLI in MSYS2..."
      & $msys2Shell -lc "pacman -S --noconfirm mingw-w64-x86_64-github-cli"

      if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Failed to install GitHub CLI."
      }
    }

    Write-Info "Authenticating gh CLI (user interaction required)..."
    & $msys2Shell -lc "export PATH=/mingw64/bin:`$PATH && gh auth login --web --clipboard --git-protocol ssh -h github.com -s public_repo,admin:public_key,admin:gpg_key --skip-ssh-key"

    if ($LASTEXITCODE -eq 0) {
      Write-Info "gh CLI authentication complete."
    } else {
      Write-WarningMsg "gh CLI authentication failed. You may need to run 'gh auth login' manually in an MSYS2 terminal."
    }

    # Create a shortcut to the MSYS2 terminal
    try {
      $userDesktop = [System.Environment]::GetFolderPath('Desktop')
      $shortcutPath = Join-Path -Path $userDesktop -ChildPath "MSYS2 Terminal.lnk"
      $shell = New-Object -COM WScript.Shell
      $shortcut = $shell.CreateShortcut($shortcutPath)
      $shortcut.TargetPath = Join-Path -Path $msys2Path -ChildPath "mingw64.exe"
      $shortcut.Save()
      Write-Info "A shortcut to the MSYS2 terminal has been created."
    } catch {
      Write-WarningMsg "Failed to create MSYS2 terminal shortcut: $($_.Exception.Message)"
    }

    Write-Info "Scoop, MSYS2, Git for Windows, and Ansible are installed."

    # Execute playbook
    Write-Info "Executing Ansible playbook..."
    $msys2LocalRepoPath = (& $msys2Shell -lc "cygpath -u '$LOCAL_REPO_PATH'" | Out-String).Trim()
    
    # We explicitly set the PATH to prioritize MSYS2 tools and avoid Windows cross-contamination
    & $msys2Shell -lc "export PATH=/usr/bin:/mingw64/bin:`$PATH && cd `"$msys2LocalRepoPath`" && ./run-playbook.sh"

    if ($LASTEXITCODE -ne 0) {
      Write-ErrorMsg "Ansible playbook execution failed with exit code $LASTEXITCODE."
    }

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
  # Handle cases where git might not be in the Windows PATH yet
  try {
    git stash --include-untracked | Out-Null
    git pull | Out-Null
    git stash pop | Out-Null
  } catch {
    Write-WarningMsg "Failed to pull latest changes. Continuing with local version."
  }
  Pop-Location
}

# Change directory to the cloned repository
Set-Location $LOCAL_REPO_PATH

# Execute the main installation function
Install-LocalMachineConfig

# Final pause
Write-Host ""
Read-Host "Press Enter to exit..."
Stop-Transcript -ErrorAction SilentlyContinue
