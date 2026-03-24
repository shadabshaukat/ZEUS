#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found at $ENV_FILE" >&2
  exit 1
fi

cd "$ROOT_DIR"

set -a
source "$ENV_FILE"
set +a

podman build \
  --build-arg ZDM_USER="$ZDM_USER" \
  --build-arg ZDM_GROUP="$ZDM_GROUP" \
  --build-arg HOME_DIR="$HOME_DIR" \
  --build-arg ZDM_HOME="$ZDM_HOME" \
  --build-arg ZDM_BASE="$ZDM_BASE" \
  --build-arg ZDM_INSTALL_LOG="$ZDM_INSTALL_LOG" \
  --build-arg ZEUS_DATA="$ZEUS_DATA" \
  --build-arg ZEUS_BASE="$ZEUS_BASE" \
  --format docker \
  -t "$IMAGE_NAME" .

podman volume inspect "$VOLUME_NAME" >/dev/null 2>&1 || podman volume create "$VOLUME_NAME" >/dev/null

echo "Build completed for image: $IMAGE_NAME"
echo "Volume ready: $VOLUME_NAME"
