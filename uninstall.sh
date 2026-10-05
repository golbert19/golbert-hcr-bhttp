#!/usr/bin/env bash
set -Eeuo pipefail

[[ ${EUID:-$(id -u)} -eq 0 ]] || {
    echo "Ejecuta como root."
    exit 1
}

systemctl disable --now \
    golbert-hcr.service \
    golbert-bhttp.service \
    golbert-badvpn.service 2>/dev/null || true

rm -f \
    /etc/systemd/system/golbert-hcr.service \
    /etc/systemd/system/golbert-bhttp.service \
    /etc/systemd/system/golbert-badvpn.service

systemctl daemon-reload
systemctl reset-failed

rm -rf /etc/golbert-vps
rm -f /usr/local/sbin/golbert-menu /usr/local/sbin/golbert-uninstall

echo "Servicios Golbert retirados."
echo "No se modificó ni eliminó SSH."
