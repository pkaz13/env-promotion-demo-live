#!/usr/bin/env bash
# Mock deploy: verify artifact hash, inject Environment config + secrets, "start" the service.
# Usage: scripts/deploy.sh <env> <artifact.zip> <expected_sha256>
# Requires DB_PASSWORD in the environment (from Key Vault or GitHub Environment secret, ADR-0003).
set -euo pipefail
env="$1"; artifact="$2"; expected="$3"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "::error::DB_PASSWORD is empty: the '$env' Environment has no secret of its own. Refusing to deploy."
  exit 1
fi

actual=$(sha256sum "$artifact" | cut -d' ' -f1)
if [[ "$actual" != "$expected" ]]; then
  echo "::error::Artifact hash mismatch: expected $expected, got $actual. Refusing to deploy a different build."
  exit 1
fi
echo "Artifact hash verified: $actual (same bytes that were built once)"

target=$(mktemp -d)
unzip -q "$artifact" -d "$target"
cp "config/$env/appsettings.json" "$target/appsettings.json"
# Token replacement, as done today with pipeline library values; source is now the Environment's secret store.
python3 - "$target/appsettings.json" <<'PY'
import os, sys, pathlib
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace("#{DB_PASSWORD}#", os.environ["DB_PASSWORD"]))
PY
python3 "$target/app.py"
