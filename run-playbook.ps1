# NOTE: PowerShell wrapper for run-playbook.sh. Ansible runs inside MSYS2 on Windows, so this finds MSYS2's
#       bash (the same locations install.ps1 uses) and passes every argument through unchanged:
#
#         .\run-playbook.ps1
#         .\run-playbook.ps1 --tags configure_keyboard
#         .\run-playbook.ps1 --syntax-check

$ErrorActionPreference = 'Stop'

$msys2Path = switch ($true) {
  { Test-Path -Path "C:\tools\msys64" } { "C:\tools\msys64"; break }
  { Test-Path -Path "C:\msys64" } { "C:\msys64"; break }
  default { "$env:USERPROFILE\scoop\apps\msys2\current" }
}

$msys2Shell = Join-Path -Path $msys2Path -ChildPath "usr\bin\bash.exe"

if (-not (Test-Path -Path $msys2Shell)) {
  Write-Host "ERROR: MSYS2 bash not found at $msys2Shell. Run install.ps1 first." -ForegroundColor Red
  exit 1
}

# NOTE: Quote each argument for bash with single quotes ('it''s' -> 'it'\''s'). The command passed to bash
#       uses no double quotes, which Windows PowerShell 5.1 mangles when passing arguments to native programs.
function ConvertTo-BashArgument {
  param([string]$Value)
  "'" + ($Value -replace "'", "'\''") + "'"
}

$repoPath = (& $msys2Shell -lc "cygpath -u $(ConvertTo-BashArgument $PSScriptRoot)" | Out-String).Trim()
$playbookArgs = ($args | ForEach-Object { ConvertTo-BashArgument "$_" }) -join ' '

# NOTE: Same environment as install.ps1: inherit the Windows PATH (Scoop, PowerShell), and have Ansible
#       write its own log, at the path documented in AGENTS.md.
$env:MSYS2_PATH_TYPE = "inherit"
$ansibleLogFile = Join-Path -Path $env:TEMP -ChildPath "local-machine-config-ansible.log"
$env:ANSIBLE_LOG_PATH = (& $msys2Shell -lc "cygpath -u $(ConvertTo-BashArgument $ansibleLogFile)" | Out-String).Trim()

# NOTE: Not piped through Out-Host, which line-buffers output and hides prompts without a trailing newline.
& $msys2Shell -lc "export PATH=/usr/bin:/mingw64/bin:`$PATH && cd $(ConvertTo-BashArgument $repoPath) && ./run-playbook.sh $playbookArgs"
exit $LASTEXITCODE
