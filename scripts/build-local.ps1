$ErrorActionPreference = 'Stop'

function Invoke-Npm([string[]]$Arguments) {
    $nodeDir = Split-Path (Get-Command npm.cmd).Source
    $node = Join-Path $nodeDir 'node.exe'
    $npm = Join-Path $nodeDir 'node_modules\npm\bin\npm-cli.js'
    $stdout = [IO.Path]::GetTempFileName()
    $stderr = [IO.Path]::GetTempFileName()
    try {
        $process = Start-Process $node -ArgumentList (@("`"$npm`"") + $Arguments) -RedirectStandardOutput $stdout -RedirectStandardError $stderr -Wait -PassThru
        [Console]::Out.Write([IO.File]::ReadAllText($stdout))
        [Console]::Error.Write([IO.File]::ReadAllText($stderr))
        if ($process.ExitCode) { exit $process.ExitCode }
    } finally {
        Remove-Item $stdout, $stderr -Force
    }
}

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    Invoke-Npm @('ci', '--no-audit')
    Invoke-Npm @('run', 'build')
    Invoke-Npm @('run', 'package')

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
