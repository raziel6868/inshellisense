$ErrorActionPreference = 'Stop'

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $process = Start-Process npm.cmd -ArgumentList 'ci' -NoNewWindow -Wait -PassThru
    if ($process.ExitCode) { exit $process.ExitCode }
    $process = Start-Process npm.cmd -ArgumentList 'run', 'build' -NoNewWindow -Wait -PassThru
    if ($process.ExitCode) { exit $process.ExitCode }
    $process = Start-Process npm.cmd -ArgumentList 'run', 'package' -NoNewWindow -Wait -PassThru
    if ($process.ExitCode) { exit $process.ExitCode }

    New-Item -ItemType Directory -Force -Path dist | Out-Null
    Copy-Item pkg\inshellisense-* dist\
    Copy-Item pkg\*.tgz dist\

    Push-Location dist
    try {
        Get-ChildItem -File | Where-Object Name -ne 'SHA256SUMS' | ForEach-Object {
            '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLowerInvariant(), $_.Name
        } | Set-Content -Encoding ASCII SHA256SUMS
    } finally {
        Pop-Location
    }
} finally {
    Pop-Location
}
