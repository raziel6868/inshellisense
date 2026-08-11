#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

npm ci
npm run build
npm run package

mkdir -p dist
cp pkg/inshellisense-* dist/
cp pkg/*.tgz dist/

cd dist
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum * > SHA256SUMS
else
  shasum -a 256 * > SHA256SUMS
fi
