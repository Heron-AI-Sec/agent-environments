#!/usr/bin/env bash
# =============================================================================
# One-command runner for a black-box attack trial against Attack_me_1.
#
# ⚠️ Research use only — run inside an isolated/disposable host.
#
# What it does:
#   1. Reprovisions the testbed (down -v && up --build -d) for a clean run,
#      satisfying scenario.yaml `reset_strategy: reprovision`.
#   2. Builds + runs the attacker container attached to frontend_net only.
#   3. The harness records every decision + command and HARD STOPS on the FLAG.
#   4. Prints the run summary and where the trace lives.
#
# Requirements:
#   * docker + compose v2
#   * ANTHROPIC_API_KEY exported (or mount a ~/.claude credential — see
#     docker-compose.attacker.yml).
#
# Usage:
#   export ANTHROPIC_API_KEY=sk-ant-...
#   ./run.sh                 # one trial
#   N_TRIALS=5 ./run.sh      # five sequential trials (stochasticity matters)
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the testbed-app docker-compose.yml relative to this dir:
# attacker -> attack_me_1 -> experiment_def -> experiment -> experiment_app
ROOT_COMPOSE="$(cd "${HERE}/../../../experiment_app/" && pwd)/docker-compose.yml"
ATTACKER_COMPOSE="${HERE}/docker-compose.attacker.yml"

if [[ ! -f "${ROOT_COMPOSE}" ]]; then
  echo "ERROR: could not find root docker-compose.yml at ${ROOT_COMPOSE}" >&2
  echo "       Edit ROOT_COMPOSE in run.sh to point at your checkout." >&2
  exit 1
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" && ! -d "${HOME}/.claude" ]]; then
  echo "ERROR: no Claude auth. Export ANTHROPIC_API_KEY or provide ~/.claude." >&2
  echo "       (To use account auth, also uncomment the ~/.claude mount in" >&2
  echo "        docker-compose.attacker.yml.)" >&2
  exit 1
fi

N_TRIALS="${N_TRIALS:-1}"
PROJECT="${COMPOSE_PROJECT_NAME:-attack_me_1}"

compose() {
  docker compose -p "${PROJECT}" -f "${ROOT_COMPOSE}" -f "${ATTACKER_COMPOSE}" "$@"
}

mkdir -p "${HERE}/runs"

for ((i = 1; i <= N_TRIALS; i++)); do
  echo "=============================================================="
  echo "[run.sh] Trial ${i}/${N_TRIALS} — reprovisioning testbed"
  echo "=============================================================="
  # Full reset for reproducibility (scenario.yaml reset_strategy: reprovision).
  compose down -v --remove-orphans || true
  compose up --build -d web backend sql

  echo "[run.sh] Waiting for web ingress to come up..."
  sleep 5

  echo "[run.sh] Launching black-box attacker (foreground)..."
  # Run the attacker in the foreground so we see the live narration; the
  # harness exits 0 on flag capture, 1 otherwise.
  set +e
  compose run --rm --build attacker
  rc=$?
  set -e

  echo "[run.sh] Attacker exited rc=${rc} (0 = FLAG captured)."
  latest="$(ls -1dt "${HERE}/runs"/*/ 2>/dev/null | head -n1 || true)"
  if [[ -n "${latest}" && -f "${latest}summary.json" ]]; then
    echo "[run.sh] Summary for trial ${i}:"
    cat "${latest}summary.json"
    echo
    echo "[run.sh] Trace dir: ${latest}"
    echo "[run.sh]   decisions -> ${latest}decisions.jsonl"
    echo "[run.sh]   commands  -> ${latest}commands.jsonl"
    echo "[run.sh]   timeline  -> ${latest}events.jsonl"
  fi
done

echo "[run.sh] Tearing down testbed..."
compose down -v --remove-orphans || true
echo "[run.sh] Done. Traces in ${HERE}/runs/"
