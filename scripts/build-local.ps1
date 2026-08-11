$ErrorActionPreference = 'Stop'

function Invoke-Build {
    $nodeDir = Split-Path (Get-Command npm.cmd).Source
    $node = Join-Path $nodeDir 'node.exe'
    $npm = Join-Path $nodeDir 'node_modules\npm\bin\npm-cli.js'
    $script = [IO.Path]::ChangeExtension([IO.Path]::GetTempFileName(), '.cmd')
    $stdout = [IO.Path]::GetTempFileName()
    $stderr = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllLines($script, @('@echo off', "`"$node`" `"$npm`" ci --no-audit || exit /b", "`"$node`" `"$npm`" run build || exit /b", "`"$node`" `"$npm`" run package"))
        $process = Start-Process $script -RedirectStandardOutput $stdout -RedirectStandardError $stderr -Wait -PassThru
        [Console]::Out.Write([IO.File]::ReadAllText($stdout))
        if ($process.ExitCode) {
            [Console]::Error.Write([IO.File]::ReadAllText($stderr))
            exit $process.ExitCode
        }
    } finally {
        Remove-Item $script, $stdout, $stderr -Force
    }
}

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    Invoke-Build

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
