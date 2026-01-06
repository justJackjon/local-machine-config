# NOTE: This script performs a destructive rollback of the installation executed by install.ps1.
#       It purges Scoop, MSYS2, Git, and the local repository configuration.

function Write-Info {
  param([string]$Message)
  Write-Host "`e[0;35mINFO: $Message`e[0m"
}

Write-Warning "This script is DESTRUCTIVE. It will remove:"
Write-Host " - $env:USERPROFILE\Repos\local-machine-config (this repository)"
Write-Host " - $env:USERPROFILE\Desktop\MSYS2 Terminal.lnk"
Write-Host " - MSYS2 and its configuration"
Write-Host " - Scoop and all applications installed through it"
Write-Host ""

$confirm = Read-Host "Are you absolutely sure you want to proceed? (y/N)"
if ($confirm -ne 'y') {
    Write-Host "Aborted."
    exit
}

# 1. Remove Desktop Shortcut
$shortcutPath = Join-Path -Path ([System.Environment]::GetFolderPath('Desktop')) -ChildPath "MSYS2 Terminal.lnk"
if (Test-Path -Path $shortcutPath) {
    Write-Info "Removing MSYS2 shortcut..."
    Remove-Item -Force $shortcutPath
}

# 2. Uninstall Scoop Packages
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Info "Uninstalling Scoop packages..."
    scoop uninstall msys2 2>$null
    scoop uninstall git 2>$null
    scoop uninstall 7zip 2>$null
}

# 3. Purge MSYS2 installation directories
$msys2Paths = @("C:\tools\msys64", "C:\msys64")
ForEach ($path in $msys2Paths) {
    if (Test-Path -Path $path) {
        Write-Info "Removing MSYS2 at $path..."
        # NOTE: Delegate to cmd.exe's rd command to mitigate filesystem locking or permission 
        #       issues frequently encountered in the native PowerShell provider.
        cmd /c "rd /s /q $path"
    }
}

# 4. Decommission Scoop environment
$scoopDir = "$env:USERPROFILE\scoop"
if (Test-Path -Path $scoopDir) {
    Write-Info "Removing Scoop directory..."
    cmd /c "rd /s /q $scoopDir"
    
    # NOTE: Sanitize the User PATH environment variable by filtering out Scoop-related entries.
    Write-Info "Cleaning up PATH..."
    $path = [Environment]::GetEnvironmentVariable("Path", "User")
    $newPath = ($path -split ';' | Where-Object { $_ -notlike "*\scoop\*" }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
}

# 5. Repository cleanup
# NOTE: Invoke a background process to perform asynchronous cleanup of the repository directory.
#       This avoids 'file in use' conflicts while the current script session remains active.
$repoPath = "$env:USERPROFILE\Repos\local-machine-config"
if (Test-Path -Path $repoPath) {
    Write-Info "The repository at $repoPath will be removed."
    Start-Process cmd -ArgumentList "/c timeout 2 && rd /s /q `"$repoPath`"" -WindowStyle Hidden
}

Write-Host ""
Write-Host "Cleanup initiated. Current PowerShell session environment may be inconsistent." -ForegroundColor Yellow
Write-Host "Terminate this window to finalize the process." -ForegroundColor Green
Read-Host "Press Enter to exit..."