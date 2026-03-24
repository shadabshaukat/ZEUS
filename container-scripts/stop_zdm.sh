#!/bin/bash

set -euo pipefail

if [[ "${ZEUS_INTERNAL_RUN:-}" != "1" ]]; then
  echo "This script is for internal use only."
  exit 1
fi

ZDM_HOME="${ZDM_HOME:-/u01/app/zdmhome}"
ZEUS_BASE="${ZEUS_BASE:-/u01/data/zeus}"
ZEUS_LOG="${ZEUS_LOG:-$ZEUS_BASE/log}"

mkdir -p "$ZEUS_LOG"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$ZEUS_LOG/stop_zdm.log"
}

log "ZDM graceful shutdown started"

if [[ -x "$ZDM_HOME/bin/zdmservice" ]]; then
  if timeout 15s "$ZDM_HOME/bin/zdmservice" stop >> "$ZEUS_LOG/stop_zdm.log" 2>&1; then
    log "ZDM graceful shutdown finished"
  else
    rc=$?
    log "ZDM graceful stop timed out or failed with rc=$rc; continuing with container stop"
  fi
else
  log "ZDM service binary not found at $ZDM_HOME/bin/zdmservice"
fi
