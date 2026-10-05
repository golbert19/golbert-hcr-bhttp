#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install -m 0644 "$ROOT_DIR/systemd/golbert-hcr.service" /etc/systemd/system/golbert-hcr.service
systemctl daemon-reload
systemctl enable golbert-hcr.service >/dev/null
systemctl restart golbert-hcr.service
sleep 1
systemctl is-active --quiet golbert-hcr.service || {
    journalctl -u golbert-hcr.service -n 40 --no-pager
    exit 1
}
