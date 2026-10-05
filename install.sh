#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/config/defaults.env"

require_root
require_ubuntu_2204

[[ "$CONTROL_URL" != *"example.com"* ]] || die \
    "Edita config/defaults.env y configura CONTROL_URL con tu dominio HTTPS."

export DEBIAN_FRONTEND=noninteractive
log "Instalando dependencias base..."
apt-get update -y
apt-get install -y ca-certificates curl socat iproute2 openssh-server ufw

SSH_PORT="$(detect_ssh_port)"
export HCR_PORT BHTTP_PORT BADVPN_PORT BADVPN_BIND SSH_PORT ENABLE_BBR

log "SSH detectado en puerto $SSH_PORT."

printf '\n'
read -rsp "Código de instalación: " INSTALL_CODE
printf '\n'
INSTALL_CODE="${INSTALL_CODE^^}"

[[ "$INSTALL_CODE" =~ ^[A-Z0-9]{16}$ ]] || die "Formato de código inválido."

RESPONSE="$(
    curl --fail-with-body --silent --show-error \
        --connect-timeout 10 --max-time 20 \
        -H 'Content-Type: application/json' \
        -X POST \
        --data "{\"code\":\"${INSTALL_CODE}\"}" \
        "${CONTROL_URL%/}/redeem" 2>/dev/null || true
)"
unset INSTALL_CODE

grep -q '"ok":true' <<<"$RESPONSE" || die "Código inválido, vencido o ya utilizado."
ok "Código autorizado."

systemctl stop golbert-hcr.service golbert-bhttp.service golbert-badvpn.service 2>/dev/null || true

for p in "$HCR_PORT" "$BHTTP_PORT"; do
    port_in_use "$p" && die "El puerto TCP $p ya está ocupado por otro servicio."
done

port_in_use "$BADVPN_PORT" && die "El puerto TCP $BADVPN_PORT ya está ocupado."

install -d -m 0755 /etc/golbert-vps
cat >/etc/golbert-vps/golbert.env <<EOF
HCR_PORT=${HCR_PORT}
BHTTP_PORT=${BHTTP_PORT}
BADVPN_PORT=${BADVPN_PORT}
BADVPN_BIND=${BADVPN_BIND}
SSH_PORT=${SSH_PORT}
EOF
chmod 0644 /etc/golbert-vps/golbert.env

log "Instalando HCR gateway..."
bash "$ROOT_DIR/modules/hcr.sh"

log "Instalando BHTTP gateway..."
bash "$ROOT_DIR/modules/bhttp.sh"

log "Instalando BadVPN UDPGW..."
bash "$ROOT_DIR/modules/badvpn.sh"

if [[ "$ENABLE_BBR" == "1" ]]; then
    log "Aplicando optimización de red..."
    bash "$ROOT_DIR/modules/optimizer.sh"
fi

log "Aplicando reglas de firewall..."
bash "$ROOT_DIR/modules/firewall.sh"

install -m 0755 "$ROOT_DIR/menu.sh" /usr/local/sbin/golbert-menu
install -m 0755 "$ROOT_DIR/uninstall.sh" /usr/local/sbin/golbert-uninstall

printf '\n'
ok "Instalación finalizada."
printf 'HCR gateway  : TCP %s\n' "$HCR_PORT"
printf 'BHTTP gateway: TCP %s\n' "$BHTTP_PORT"
printf 'BadVPN UDPGW : %s:%s\n' "$BADVPN_BIND" "$BADVPN_PORT"
printf 'SSH backend  : TCP %s\n' "$SSH_PORT"
printf '\nUsa: golbert-menu\n'
