#!/bin/bash

set -euo pipefail

ZDM_HOME="${ZDM_HOME:?ZDM_HOME must be set}"
ZDM_INSTALL_LOG="${ZDM_INSTALL_LOG:-/u01/log}"
LOG_FILE="$ZDM_INSTALL_LOG/zdm_install.log"

mkdir -p "$ZDM_INSTALL_LOG"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

ZDM_SERVICE_BIN="${ZDM_HOME%/}/bin/zdmservice"

log "start_zdm.sh started"
log "ZDM_HOME=$ZDM_HOME"

if [[ ! -x "$ZDM_SERVICE_BIN" ]]; then
  log "ERROR: ZDM service binary not found: $ZDM_SERVICE_BIN"
  exit 1
fi

log "Starting ZDM service"
"$ZDM_SERVICE_BIN" start >> "$LOG_FILE" 2>&1

log "ZDM service start command completed"

if ! "$ZDM_SERVICE_BIN" status >> "$LOG_FILE" 2>&1; then
  log "ERROR: ZDM service status check failed after start"
  exit 1
fi

log "ZDM service started successfully"
