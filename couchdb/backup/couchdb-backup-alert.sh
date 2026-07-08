#!/usr/bin/env bash
# Disparado pelo OnFailure= do couchdb-backup.service.
# Empurra um alerta direto pra API do Alertmanager → que já roteia pro Discord.
set -euo pipefail
AM="http://localhost:9093/api/v2/alerts"
curl -sf -XPOST "$AM" -H 'Content-Type: application/json' -d '[{
  "labels": {
    "alertname": "CouchDBBackupFailed",
    "severity": "critical",
    "job": "couchdb-backup",
    "instance": "homelab"
  },
  "annotations": {
    "summary": "Backup do CouchDB falhou",
    "description": "couchdb-backup.service terminou com erro. Verifique: journalctl -u couchdb-backup.service -n 50"
  }
}]' >/dev/null && echo "Alerta enviado ao Alertmanager." || echo "Falha ao enviar alerta ao Alertmanager." >&2
