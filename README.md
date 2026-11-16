# env-promotion-demo (live)

Synthetic demo: strict environment isolation, build-once promotion by hash, and a deterministic guardrail against cross-environment config.

- `.github/workflows/deliver.yml`: build once → `dev` → `staging` → `prod`, each deploy verifies the same sha256 and uses only its own Environment's secrets.
- `.github/workflows/guardrail.yml`: `env-isolation` check on every PR.
- `scripts/check-env-isolation.py` + `policy/resource-ownership.json`: same check for humans, AI agents and CI.
