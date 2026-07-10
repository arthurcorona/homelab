#!/usr/bin/env bash
# Instala/atualiza as regras DOCKER-USER a partir desta pasta (fonte canônica).
# Rodar com sudo após qualquer edição.
set -euo pipefail
cd "$(dirname "$0")"

[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo."; exit 1; }

install -o root -g root -m 755 docker-user-rules.sh /usr/local/bin/docker-user-rules.sh
install -o root -g root -m 644 docker-user.service  /etc/systemd/system/docker-user.service

systemctl daemon-reload
systemctl enable --now docker-user.service

echo "OK. Estado atual da chain:"
iptables -nL DOCKER-USER --line-numbers
