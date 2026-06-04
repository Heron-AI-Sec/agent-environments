#!/usr/bin/env bash
# =============================================================================
# One-command runner for a black-box attack trial against Attack_me_1.
#
# Research use only - run inside an isolated/disposable host.
#
# What it does:
#   1. Reprovisions the testbed (down -v && up --build -d) for a clean run,
#      satisfying scenario.yaml `reset_strategy: reprovision`.
#   2. Builds + runs the attacker container attached to frontend_net only.
#   3. The harness records every decision + command and HARD STOPS on the FLAG.
#   4. Captures target-service logs alongside the attacker trace.
#   5. Prints the run summary and where the trace lives.
#
# Requirements:
#   * docker + compose v2
#   * ANTHROPIC_API_KEY exported (or mount a ~/.claude credential - see
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
# attacker -> experiment -> experiment_app
ROOT_COMPOSE="$(cd "${HERE}/../experiment_app/" && pwd)/docker-compose.yml"
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
  run_id="$(date -u +%Y%m%dT%H%M%SZ)-$(printf '%04x%04x' "$((RANDOM % 65536))" "$((RANDOM % 65536))")"
  run_dir="${HERE}/runs/${run_id}"
  mkdir -p "${run_dir}"

  echo "=============================================================="
  echo "[run.sh] Trial ${i}/${N_TRIALS} - reprovisioning testbed"
  echo "=============================================================="
  compose down -v --remove-orphans || true
  compose up --build -d web backend sql

  echo "[run.sh] Waiting for web ingress to come up..."
  sleep 5

  echo "[run.sh] Capturing web/backend/sql logs to ${run_dir}/services.log"
  compose logs -f --no-color web backend sql > "${run_dir}/services.log" 2>&1 &
  logs_pid=$!

  echo "[run.sh] Launching black-box attacker (foreground)..."
  set +e
  RUN_ID="${run_id}" compose run --rm --build attacker
  rc=$?
  set -e

  kill "${logs_pid}" 2>/dev/null || true
  wait "${logs_pid}" 2>/dev/null || true

  echo "[run.sh] Attacker exited rc=${rc} (0 = FLAG captured)."
  if [[ -f "${run_dir}/summary.json" ]]; then
    echo "[run.sh] Summary for trial ${i}:"
    cat "${run_dir}/summary.json"
    echo
    echo "[run.sh] Trace dir: ${run_dir}/"
    echo "[run.sh]   decisions -> ${run_dir}/decisions.jsonl"
    echo "[run.sh]   commands  -> ${run_dir}/commands.jsonl"
    echo "[run.sh]   timeline  -> ${run_dir}/events.jsonl"
    echo "[run.sh]   services  -> ${run_dir}/services.log"
  fi
done

echo "[run.sh] Tearing down testbed..."
compose down -v --remove-orphans || true
echo "[run.sh] Done. Traces in ${HERE}/runs/"
