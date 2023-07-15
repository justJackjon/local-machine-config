# NOTE: This script must be run with Administrator privileges.

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
$msys2Installed = $msys2Paths | ForEach-Object { if (Test-Path -Path $_) { $true; break } }

if (-not $msys2Installed) {
    # Install MSYS2
    choco install msys2 -y
} else {
    Write-Host "MSYS2 is already installed."
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

# Create a shortcut to the MSYS2 terminal on the desktop
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\MSYS2 Terminal.lnk")
$Shortcut.TargetPath = Join-Path -Path $msys2Path -ChildPath "mingw64.exe"
$Shortcut.Save()

Write-Host "MSYS2 and Ansible have been installed successfully. A shortcut to the MSYS2 terminal has been created on your desktop. You can now use this terminal to run Ansible playbooks."
