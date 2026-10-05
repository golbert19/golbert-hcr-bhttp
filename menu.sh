#!/usr/bin/env bash
set -Eeuo pipefail

while true; do
    clear
    cat <<'EOF'
=====================================
          GOLBERT VPS MANAGER
=====================================
1) Estado de servicios
2) Reiniciar HCR
3) Reiniciar BHTTP
4) Reiniciar BadVPN
5) Reiniciar todos
6) Logs HCR
7) Logs BHTTP
8) Logs BadVPN
9) Ver puertos
0) Salir
=====================================
EOF
    read -rp "Opción: " op

    case "$op" in
        1)
            systemctl --no-pager --full status golbert-hcr.service || true
            systemctl --no-pager --full status golbert-bhttp.service || true
            systemctl --no-pager --full status golbert-badvpn.service || true
            read -rp "ENTER..."
            ;;
        2) systemctl restart golbert-hcr ;;
        3) systemctl restart golbert-bhttp ;;
        4) systemctl restart golbert-badvpn ;;
        5) systemctl restart golbert-hcr golbert-bhttp golbert-badvpn ;;
        6) journalctl -u golbert-hcr -n 100 --no-pager; read -rp "ENTER..." ;;
        7) journalctl -u golbert-bhttp -n 100 --no-pager; read -rp "ENTER..." ;;
        8) journalctl -u golbert-badvpn -n 100 --no-pager; read -rp "ENTER..." ;;
        9) ss -lntp | grep -E ':(8180|8080|7300)\b' || true; read -rp "ENTER..." ;;
        0) exit 0 ;;
    esac
done
