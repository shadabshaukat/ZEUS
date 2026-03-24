#!/bin/bash

set -euo pipefail

systemctl --user stop zeus.service
echo "ZEUS service stopped."
