#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/golbert19/golbert-vps.git"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Ejecuta como root."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git ca-certificates curl

git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo"
exec bash "$TMP_DIR/repo/install.sh"
