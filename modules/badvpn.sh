#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x /usr/local/bin/badvpn-udpgw ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y git cmake build-essential

    WORKDIR="$(mktemp -d)"
    trap 'rm -rf "$WORKDIR"' EXIT

    git clone --depth 1 https://github.com/ambrop72/badvpn.git "$WORKDIR/badvpn"

    cmake \
        -S "$WORKDIR/badvpn" \
        -B "$WORKDIR/badvpn/build" \
        -DBUILD_NOTHING_BY_DEFAULT=1 \
        -DBUILD_UDPGW=1

    cmake --build "$WORKDIR/badvpn/build" -j"$(nproc)"

    BIN="$(find "$WORKDIR/badvpn/build" -type f -name badvpn-udpgw -perm -111 | head -1)"
    [[ -n "$BIN" ]] || {
        echo "No se generó badvpn-udpgw." >&2
        exit 1
    }

    install -m 0755 "$BIN" /usr/local/bin/badvpn-udpgw
fi

install -m 0644 "$ROOT_DIR/systemd/golbert-badvpn.service" /etc/systemd/system/golbert-badvpn.service
systemctl daemon-reload
systemctl enable golbert-badvpn.service >/dev/null
systemctl restart golbert-badvpn.service
sleep 1
systemctl is-active --quiet golbert-badvpn.service || {
    journalctl -u golbert-badvpn.service -n 40 --no-pager
    exit 1
}
