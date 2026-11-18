#!/usr/bin/env bash
set -euo pipefail

required_files=(
  docker-compose.yaml
  docker-compose.deploy.yml
  backend/Dockerfile
  backend/package.json
  backend/db/init.sql
  backend/src/server.js
  frontend/Dockerfile
  frontend/package.json
  frontend/nginx.conf
)

missing=0
for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file"
    missing=1
  fi
done

exit "$missing"
