#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install -m 0644 "$ROOT_DIR/systemd/golbert-bhttp.service" /etc/systemd/system/golbert-bhttp.service
systemctl daemon-reload
systemctl enable golbert-bhttp.service >/dev/null
systemctl restart golbert-bhttp.service
sleep 1
systemctl is-active --quiet golbert-bhttp.service || {
    journalctl -u golbert-bhttp.service -n 40 --no-pager
    exit 1
}
