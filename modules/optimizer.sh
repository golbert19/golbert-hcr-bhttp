#!/usr/bin/env bash
set -Eeuo pipefail

modprobe tcp_bbr 2>/dev/null || true
AVAILABLE="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"

if grep -qw bbr <<<"$AVAILABLE"; then
    cat >/etc/sysctl.d/99-golbert-network.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
EOF
    sysctl --system >/dev/null
    echo "BBR + fq activado."
else
    echo "BBR no está disponible en este kernel; no se fuerza ningún valor."
fi
