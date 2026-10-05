#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

require_root() {
    [[ ${EUID:-$(id -u)} -eq 0 ]] || die "Ejecuta como root."
}

require_ubuntu_2204() {
    [[ -r /etc/os-release ]] || die "No se encontró /etc/os-release."
    source /etc/os-release
    [[ "${ID:-}" == "ubuntu" ]] || die "Solo Ubuntu está soportado."
    [[ "${VERSION_ID:-}" == "22.04" ]] || die "Esta versión está preparada para Ubuntu 22.04."
}

detect_ssh_port() {
    local p
    p="$(sshd -T 2>/dev/null | awk '$1=="port"{print $2; exit}')" || true
    printf '%s\n' "${p:-22}"
}

port_in_use() {
    local port="$1"
    ss -H -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)$port$"
}
