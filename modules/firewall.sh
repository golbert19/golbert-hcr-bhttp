#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/golbert-vps/golbert.env

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
    ufw allow "${SSH_PORT}/tcp" comment 'Golbert SSH' >/dev/null
    ufw allow "${HCR_PORT}/tcp" comment 'Golbert HCR' >/dev/null
    ufw allow "${BHTTP_PORT}/tcp" comment 'Golbert BHTTP' >/dev/null
fi
