# Agent instructions

Synthetic demo of strict environment isolation and build-once promotion. All hosts, tenants and secrets are fake.

- Environments: `dev`, `staging`, `prod`. Non-secret config lives in `config/<env>/`; secrets live only in GitHub Environment secrets.
- Before proposing any change under `config/` or `policy/`, run `python3 scripts/check-env-isolation.py` and fix every reported violation. Never make one environment's config reference a resource owned by another (see `policy/resource-ownership.json`).
- Never change workflows to deploy to `prod` outside the `deliver` pipeline.
