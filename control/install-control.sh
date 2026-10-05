#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ ${EUID:-$(id -u)} -eq 0 ]] || {
    echo "Ejecuta como root."
    exit 1
}

source /etc/os-release
[[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "22.04" ]] || {
    echo "Preparado para Ubuntu 22.04."
    exit 1
}

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-venv nginx ca-certificates

if ! id golbertctl >/dev/null 2>&1; then
    useradd --system --home /opt/golbert-control --shell /usr/sbin/nologin golbertctl
fi

install -d -o golbertctl -g golbertctl -m 0750 /opt/golbert-control
install -d -o golbertctl -g golbertctl -m 0750 /var/lib/golbert-control

install -m 0644 "$ROOT_DIR/api.py" /opt/golbert-control/api.py
install -m 0644 "$ROOT_DIR/bot.py" /opt/golbert-control/bot.py
install -m 0644 "$ROOT_DIR/db.py" /opt/golbert-control/db.py
install -m 0644 "$ROOT_DIR/requirements.txt" /opt/golbert-control/requirements.txt

python3 -m venv /opt/golbert-control/venv
/opt/golbert-control/venv/bin/pip install --upgrade pip
/opt/golbert-control/venv/bin/pip install -r /opt/golbert-control/requirements.txt

chown -R golbertctl:golbertctl /opt/golbert-control /var/lib/golbert-control

if [[ ! -f /etc/golbert-control.env ]]; then
    install -m 0600 "$ROOT_DIR/golbert-control.env.example" /etc/golbert-control.env
    echo "IMPORTANTE: edita /etc/golbert-control.env antes de iniciar el bot."
fi

install -m 0644 "$ROOT_DIR/systemd/golbert-control-api.service" /etc/systemd/system/golbert-control-api.service
install -m 0644 "$ROOT_DIR/systemd/golbert-control-bot.service" /etc/systemd/system/golbert-control-bot.service

systemctl daemon-reload
systemctl enable golbert-control-api.service golbert-control-bot.service

echo
echo "Control instalado."
echo "1) Edita /etc/golbert-control.env"
echo "2) Configura Nginx + HTTPS"
echo "3) Inicia: systemctl restart golbert-control-api golbert-control-bot"
