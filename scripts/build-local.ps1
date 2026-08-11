Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    npm ci
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    npm run build
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    npm run package
    if ($LASTEXITCODE) { exit $LASTEXITCODE }

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
