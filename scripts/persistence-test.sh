#!/usr/bin/env bash
set -euo pipefail

marker="ci-persistence-$(date +%s)"

docker compose exec -T postgres psql \
  -U "${POSTGRES_USER:-taskflow_user}" \
  -d "${POSTGRES_DB:-taskflow}" \
  -v ON_ERROR_STOP=1 \
  -c "CREATE TABLE IF NOT EXISTS ci_persistence_check (marker text PRIMARY KEY); INSERT INTO ci_persistence_check(marker) VALUES ('$marker');"

docker compose restart postgres

for attempt in $(seq 1 30); do
  if docker compose exec -T postgres pg_isready -U "${POSTGRES_USER:-taskflow_user}" -d "${POSTGRES_DB:-taskflow}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

count=$(docker compose exec -T postgres psql \
  -U "${POSTGRES_USER:-taskflow_user}" \
  -d "${POSTGRES_DB:-taskflow}" \
  -tAc "SELECT COUNT(*) FROM ci_persistence_check WHERE marker = '$marker';")

if [[ "$count" -ne 1 ]]; then
  echo "PostgreSQL persistence check failed"
  exit 1
fi

docker compose exec -T postgres psql \
  -U "${POSTGRES_USER:-taskflow_user}" \
  -d "${POSTGRES_DB:-taskflow}" \
  -c "DROP TABLE ci_persistence_check;"

echo "PostgreSQL persistence check passed"
