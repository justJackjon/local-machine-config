# NOTE: This script must be run with Administrator privileges.

try {
# Check if Chocolatey is installed
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
      # Install Chocolatey
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
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

# Create a shortcut to the MSYS2 terminal on the public desktop
  $shell = New-Object -COM WScript.Shell
  $shortcut = $shell.CreateShortcut("C:\Users\Public\Desktop\MSYS2 Terminal.lnk")
  $shortcut.TargetPath = Join-Path -Path $msys2Path -ChildPath "mingw64.exe"
  $shortcut.Save()

  Write-Host "`n`nMSYS2 and Ansible are installed. A shortcut to the MSYS2 terminal has been created on your desktop." -ForegroundColor Green
  Write-Host "You can now use the MSYS2 terminal to run Ansible playbooks.`n" -ForegroundColor Green
} catch {
  Write-Host "`n$($_.Exception.ToString())" -ForegroundColor Red
  Write-Host "`n`nAn error occurred during the installation process." -ForegroundColor Red
  Write-Host "`nPlease ensure you are running this script from an elevated PowerShell prompt." -ForegroundColor Magenta
  Write-Host "If the error persists, please check the error message above for more details.`n" -ForegroundColor Red
}
