#!/usr/bin/env bash
# Reset the live demo to its opening state:
#   no environments, no secrets, no rulesets, no open PRs or extra branches,
#   and a fresh `deliver` run whose deploy-dev fails with "DB_PASSWORD is empty".
#
# Usage: scripts/reset-demo.sh [--repo OWNER/REPO] [--yes] [--dry-run]
#   --repo     target repo (default: the repo of the current directory)
#   --yes      skip the confirmation prompt (for agents / automation)
#   --dry-run  only print what would be deleted
# Requires: gh CLI authenticated with admin rights on the repo.
set -euo pipefail

repo=""; yes=false; dry=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --yes) yes=true; shift ;;
    --dry-run) dry=true; shift ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
repo="${repo:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
default_branch=$(gh api "repos/$repo" --jq .default_branch)

envs=$(gh api "repos/$repo/environments" --jq '.environments[].name')
rulesets=$(gh api "repos/$repo/rulesets" --jq '.[] | "\(.id) \(.name)"')
prs=$(gh pr list -R "$repo" --state open --json number --jq '.[].number')
branches=$(gh api "repos/$repo/branches" --paginate --jq ".[].name | select(. != \"$default_branch\")")

echo "Reset target: $repo (default branch: $default_branch)"
echo "  environments to delete : ${envs:-none}" | tr '\n' ' '; echo
echo "  rulesets to delete     : ${rulesets:-none}" | tr '\n' ' '; echo
echo "  open PRs to close      : ${prs:-none}" | tr '\n' ' '; echo
echo "  branches to delete     : ${branches:-none}" | tr '\n' ' '; echo
echo "  then: trigger a fresh 'deliver' run (expected: deploy-dev fails, no secret)"

if $dry; then echo "Dry run: nothing changed."; exit 0; fi
if ! $yes; then
  read -r -p "Proceed? [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

for n in $prs; do gh pr close "$n" -R "$repo" >/dev/null && echo "closed PR #$n"; done
for b in $branches; do gh api -X DELETE "repos/$repo/git/refs/heads/$b" && echo "deleted branch $b"; done
while read -r id name; do
  [[ -n "${id:-}" ]] && gh api -X DELETE "repos/$repo/rulesets/$id" && echo "deleted ruleset $name"
done <<< "$rulesets"
# Deleting an environment also deletes its secrets, variables and protection rules.
for e in $envs; do gh api -X DELETE "repos/$repo/environments/$e" && echo "deleted environment $e"; done

gh workflow run deliver.yml -R "$repo" --ref "$default_branch"
echo "Triggered a fresh 'deliver' run. Opening state is ready once deploy-dev turns red:"
echo "  https://github.com/$repo/actions/workflows/deliver.yml"
