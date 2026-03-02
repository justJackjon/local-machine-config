# NOTE: This script is the primary installation script for setting up a Windows development environment.
#       It must be run with Administrator privileges from a native Windows PowerShell prompt.

function Write-Info {
  param([string]$Message)
  Write-Host "INFO: $Message" -ForegroundColor Magenta
}

function Write-ErrorMsg {
  param(
    [string]$Message,
    [switch]$NoExit
  )
  Write-Host "ERROR: $Message" -ForegroundColor Red

  if (-not $NoExit) {
    Write-Host ""
    Read-Host "Press Enter to exit..."
    Stop-Transcript -ErrorAction SilentlyContinue
    exit 1
  }
}

function Write-WarningMsg {
  param([string]$Message)
  Write-Host "
-------------------------------------------------------------------------------------------------------------------------------------------------
  WARNING: $Message
-------------------------------------------------------------------------------------------------------------------------------------------------
" -ForegroundColor Yellow
}

function Write-Note {
  param([string]$Message)
  Write-Host "NOTE: $Message" -ForegroundColor Cyan
}

if ($PSVersionTable.OS -and ($PSVersionTable.OS -notlike "*Windows*")) {
  Write-ErrorMsg "This script is intended to be run on Windows. Please use install.sh for Linux/macOS."
}

$logFile = Join-Path -Path $env:TEMP -ChildPath "local-machine-config-install.log"
Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue
Write-Info "Running on Windows"
Write-Note "Transcript logging started. Logs will be saved to: $logFile"

$REPO_DIR = "$env:USERPROFILE\Repos"
$LOCAL_REPO_PATH = "$REPO_DIR\local-machine-config"

function Install-Dependencies {
  try {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
      Write-Info "Installing Scoop..."
      
      # NOTE: Attempt to set the execution policy to RemoteSigned for the current user.
      # We wrap this in a try-catch because Group Policy may prevent changing this setting,
      # but the script may still work if the current session is already bypassed.
      try {
        $effectivePolicy = Get-ExecutionPolicy
        if ($effectivePolicy -notmatch 'RemoteSigned|Unrestricted|Bypass') {
          Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        }
      } catch {
        Write-WarningMsg "Unable to set ExecutionPolicy to RemoteSigned. This is usually due to Group Policy restrictions. Attempting to continue..."
      }

      # NOTE: Install Scoop using the most compatible method available (Invoke-RestMethod with WebClient fallback).
      if (Get-Command Invoke-RestMethod -ErrorAction SilentlyContinue) {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
      } else {
        $webClient = New-Object System.Net.WebClient
        Invoke-Expression $webClient.DownloadString('https://get.scoop.sh')
      }

      $env:PATH = "$env:USERPROFILE\scoop\shims;$env:PATH"
    } else {
      Write-Host "Scoop is already installed."
    }

    $msys2Paths = @("C:\tools\msys64", "C:\msys64")
    $msys2Installed = $false

    ForEach ($path in $msys2Paths) {
      if (Test-Path -Path $path) {
        $msys2Installed = $true
        break
      }
    }

    if (-not $msys2Installed) {
      Write-Info "Installing MSYS2 via Scoop..."
      scoop install msys2
    } else {
      Write-Host "MSYS2 is already installed."
    }

    $msys2Path = switch ($true) {
      { Test-Path -Path "C:\tools\msys64" } { "C:\tools\msys64"; break }
      { Test-Path -Path "C:\msys64" } { "C:\msys64"; break }
      default { "$env:USERPROFILE\scoop\apps\msys2\current" }
    }

    $msys2Shell = Join-Path -Path $msys2Path -ChildPath "usr\bin\bash.exe"

    # NOTE: Perform an MSYS2 initialization "warm-up" to trigger post-install scripts.
    Write-Info "Performing MSYS2 initialization (this may take a moment)..."
    & $msys2Shell -lc "echo 'MSYS2 shell initialized'"
    
    # NOTE: Sometimes MSYS2 requires a brief delay or multiple shell invocations 
    #       to finish populating the user's home directory.
    Start-Sleep -Seconds 2
    & $msys2Shell -lc "echo 'Environment check: ' && whoami && pwd"

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      Write-Info "Installing Git for Windows via Scoop..."
      scoop install git
      if ($env:PATH -notlike "*\scoop\shims*") {
        $env:PATH = "$env:USERPROFILE\scoop\shims;$env:PATH"
      }
    } else {
      Write-Host "Git for Windows is already installed."
    }

    Write-Info "Checking for Ansible in MSYS2 environment..."
    $ansibleCheck = & $msys2Shell -lc "which ansible-playbook 2>/dev/null"

    if (-not $ansibleCheck) {
      Write-Info "Installing Ansible in MSYS2..."
      & $msys2Shell -lc "pacman -Syu --noconfirm"
      & $msys2Shell -lc "pacman -S --noconfirm base-devel ansible"
    } else {
      Write-Host "Ansible is already installed in MSYS2."
    }

    Write-Info "Installing Ansible collections..."
    & $msys2Shell -lc "ansible-galaxy collection install community.general ansible.windows community.crypto community.windows"

    $ghCheck = & $msys2Shell -lc "export PATH=/mingw64/bin:`$PATH && which gh 2>/dev/null"

    if (-not $ghCheck) {
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
    return $msys2Shell
  } catch {
    Write-ErrorMsg "$($_.Exception.ToString())" -NoExit
    Write-Host ""
    Write-ErrorMsg "An error occurred during the installation process." -NoExit
    Write-ErrorMsg "Please ensure you are running this script from an elevated PowerShell prompt." -NoExit
    Write-ErrorMsg "If the error persists, please check the error message above for more details."
  }
}

function Execute-Playbook {
  param([string]$msys2Shell)
  Write-Info "Executing Ansible playbook..."
  $msys2LocalRepoPath = (& $msys2Shell -lc "cygpath -u '$LOCAL_REPO_PATH'" | Out-String).Trim()
  
  # NOTE: Set MSYS2_PATH_TYPE to inherit to ensure Windows-native environment variables 
  #       (like SystemRoot, TEMP, etc.) are preserved for Scoop and PowerShell.
  $env:MSYS2_PATH_TYPE = "inherit"
  & $msys2Shell -lc "export PATH=/usr/bin:/mingw64/bin:`$PATH && cd `"$msys2LocalRepoPath`" && ./run-playbook.sh"

  if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Ansible playbook execution failed with exit code $LASTEXITCODE."
  }

  Write-Info "`nSetup complete! Please review the output above for any errors.`n"
}

$msys2Shell = Install-Dependencies

if (-not (Test-Path -Path $LOCAL_REPO_PATH)) {
  Write-Info "Cloning repository to $LOCAL_REPO_PATH..."
  New-Item -ItemType Directory -Force -Path $REPO_DIR | Out-Null
  git clone https://github.com/justjackjon/local-machine-config.git $LOCAL_REPO_PATH
} else {
  Write-Info "Repository already cloned. Pulling latest changes."
  Push-Location $LOCAL_REPO_PATH
  # NOTE: Handle scenarios where git may not yet be available in the PowerShell PATH by catching the exception.
  try {
    git stash --include-untracked | Out-Null
    git pull | Out-Null
    git stash pop | Out-Null
  } catch {
    Write-WarningMsg "Failed to pull latest changes. Continuing with local version."
  }
  Pop-Location
}

Set-Location $LOCAL_REPO_PATH
Execute-Playbook -msys2Shell $msys2Shell

Write-Host ""
Read-Host "Press Enter to exit..."
Stop-Transcript -ErrorAction SilentlyContinue
