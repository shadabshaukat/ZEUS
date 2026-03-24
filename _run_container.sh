#!/bin/bash

set -euo pipefail

if [[ "${ZEUS_INTERNAL_RUN:-}" != "1" ]]; then
  echo "This script is for internal use only."
  echo "Please use ./run.sh instead."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
HOSTS_FILE="$ROOT_DIR/.hosts"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found at $ENV_FILE" >&2
  exit 1
fi

cd "$ROOT_DIR"

set -a
source "$ENV_FILE"
set +a

CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-zdm}"
CONTAINER_NAME="${CONTAINER_NAME:-zeus}"
IMAGE_NAME="${IMAGE_NAME:-zeus:latest}"
VOLUME_NAME="${VOLUME_NAME:-zdm_volume}"

podman volume inspect "$VOLUME_NAME" >/dev/null 2>&1 || podman volume create "$VOLUME_NAME" >/dev/null

if podman container exists "$CONTAINER_NAME"; then
  echo "Container '$CONTAINER_NAME' already exists. Skipping podman run."
  exit 0
fi

ADD_HOST_FLAGS=()
if [[ -f "$HOSTS_FILE" ]]; then
  while IFS=' ' read -r ip fqdn hostname; do
    [[ -z "${ip:-}" || -z "${hostname:-}" ]] && continue
    [[ "$ip" =~ ^# ]] && continue
    ADD_HOST_FLAGS+=(--add-host "${hostname}:${ip}")
  done < "$HOSTS_FILE"
fi

CMD=(
  podman run
  --restart=always
  --userns=keep-id
  --network host
  -d
  --hostname "$CONTAINER_HOSTNAME"
  -v "${VOLUME_NAME}:/u01:Z"
  "${ADD_HOST_FLAGS[@]}"
  --name "$CONTAINER_NAME"
  "$IMAGE_NAME"
)

echo "Executing command:"
printf ' %q' "${CMD[@]}"
echo

exec "${CMD[@]}"
