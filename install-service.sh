#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$UNIT_DIR/zeus.service"

if ! loginctl show-user "$USER" -p Linger 2>/dev/null | grep -q 'Linger=yes'; then
  echo "Linger is not enabled for user $USER."
  echo "Please run the following command once, then rerun this script:"
  echo
  echo "  sudo loginctl enable-linger $USER"
  echo
  exit 1
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

CONTAINER_NAME="${CONTAINER_NAME:-zeus}"

mkdir -p "$UNIT_DIR"

cat > "$UNIT_FILE" <<EOF
[Unit]
Description=ZEUS rootless Podman container
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$ROOT_DIR
Environment=ZEUS_INTERNAL_RUN=1

ExecStart=$ROOT_DIR/_run_container.sh

# Stop ZEUS app processes first
ExecStop=/usr/bin/timeout 40s /usr/bin/podman exec --user zdmuser -e ZEUS_INTERNAL_RUN=1 $CONTAINER_NAME /bin/bash /home/zdmuser/stop_zeus.sh

# stop_zdm.sh already has its own internal timeout; do not wrap it with another short timeout
ExecStop=/usr/bin/podman exec --user zdmuser -e ZEUS_INTERNAL_RUN=1 $CONTAINER_NAME /bin/bash /home/zdmuser/stop_zdm.sh

# Then stop and remove the container itself
ExecStop=/usr/bin/podman stop -t 30 $CONTAINER_NAME
ExecStopPost=/usr/bin/podman rm -f $CONTAINER_NAME

TimeoutStartSec=0
TimeoutStopSec=180

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload

echo "Installed/updated systemd user service:"
echo "  $UNIT_FILE"
