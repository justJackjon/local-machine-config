# NOTE: This script must be run with Administrator privileges

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Check if MSYS2 is installed
if (-not (Test-Path -Path "C:\tools\msys64" -or Test-Path -Path "C:\msys64")) {
    # Install MSYS2
    choco install msys2
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
}
