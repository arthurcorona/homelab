#!/usr/bin/env bash
# Instala/atualiza o backup do CouchDB a partir desta pasta (fonte canônica).
# Copia (não symlinka) para que root nunca execute arquivo gravável pelo usuário.
# Rodar com sudo após qualquer edição nos scripts/units daqui.
set -euo pipefail
cd "$(dirname "$0")"

[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo."; exit 1; }

install -o root -g root -m 755 couchdb-backup.sh       /usr/local/bin/couchdb-backup.sh
install -o root -g root -m 755 couchdb-backup-alert.sh /usr/local/bin/couchdb-backup-alert.sh
install -o root -g root -m 644 couchdb-backup.service       /etc/systemd/system/
install -o root -g root -m 644 couchdb-backup.timer         /etc/systemd/system/
install -o root -g root -m 644 couchdb-backup-alert.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now couchdb-backup.timer

echo "OK. Próximas execuções:"
systemctl list-timers couchdb-backup.timer --no-pager
