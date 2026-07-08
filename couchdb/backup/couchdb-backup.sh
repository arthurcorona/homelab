#!/usr/bin/env bash
# Backup diário do CouchDB (Obsidian Self-hosted LiveSync).
# Cópia a QUENTE (sem downtime): os .couch são append-only, então o snapshot
# é consistente até o último commit. Gera .tar.gz + sha256 em subpasta mensal
# (AAAA-MM/), aplica retenção e publica métricas pro node-exporter
# (dead man's switch via Prometheus).
#
# Fonte canônica: /home/homelab/docker/couchdb/backup/couchdb-backup.sh
# Instalado em /usr/local/bin via ./install.sh — edite AQUI e re-rode o install.
set -euo pipefail

# ── Config (trocar DEST_ROOT quando migrar p/ HDD dedicado / nuvem) ────────
STACK_DIR="/home/homelab/docker/couchdb"
DATA_DIR="${STACK_DIR}/data"
DEST_ROOT="/home/homelab/backups/couchdb"
STAGING="/home/homelab/backups/.couchdb-staging"
RETENTION_DAYS=14
LOCKFILE="/run/couchdb-backup.lock"
TEXTFILE_DIR="/var/lib/node_exporter/textfile"
METRIC_FILE="${TEXTFILE_DIR}/couchdb_backup.prom"

START="$(date +%s)"
TS="$(date +%Y%m%d-%H%M%S)"
DEST="${DEST_ROOT}/$(date +%Y-%m)"          # subpasta mensal: AAAA-MM/
ARTIFACT="${DEST}/couchdb-${TS}.tar.gz"

mkdir -p "$DEST" "$STAGING" "$TEXTFILE_DIR"

prev_success_ts() {
  grep -E '^couchdb_backup_last_success_timestamp_seconds ' "$METRIC_FILE" 2>/dev/null \
    | awk '{print $2}' | tail -1
}

write_metrics() {  # success duration size last_success_ts
  local success="$1" duration="$2" size="$3" lsts="$4"
  local tmp="${METRIC_FILE}.tmp.$$"
  {
    echo "# HELP couchdb_backup_success Ultima execucao: 1=sucesso 0=falha"
    echo "# TYPE couchdb_backup_success gauge"
    echo "couchdb_backup_success ${success}"
    echo "# HELP couchdb_backup_duration_seconds Duracao da ultima execucao"
    echo "# TYPE couchdb_backup_duration_seconds gauge"
    echo "couchdb_backup_duration_seconds ${duration}"
    echo "# HELP couchdb_backup_size_bytes Tamanho do ultimo artefato em bytes"
    echo "# TYPE couchdb_backup_size_bytes gauge"
    echo "couchdb_backup_size_bytes ${size}"
    echo "# HELP couchdb_backup_last_success_timestamp_seconds Unix time do ultimo sucesso"
    echo "# TYPE couchdb_backup_last_success_timestamp_seconds gauge"
    echo "couchdb_backup_last_success_timestamp_seconds ${lsts}"
  } > "$tmp"
  mv "$tmp" "$METRIC_FILE"
}

fail() {
  echo "BACKUP FALHOU: $1" >&2
  local prev; prev="$(prev_success_ts)"; prev="${prev:-0}"
  write_metrics 0 "$(( $(date +%s) - START ))" 0 "$prev"
  exit 1
}

# ── Trava: nunca dois backups simultâneos ──────────────────────────────────
exec 9>"$LOCKFILE"
flock -n 9 || { echo "Outro backup em andamento; abortando."; exit 0; }

[ -d "$DATA_DIR" ] || fail "data dir inexistente: $DATA_DIR"

echo "[$(date -Is)] Snapshot a quente de ${DATA_DIR} ..."
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${DATA_DIR}/" "${STAGING}/data/" || fail "rsync falhou"
else
  rm -rf "${STAGING:?}/data"; cp -a "$DATA_DIR" "${STAGING}/data" || fail "cp falhou"
fi

echo "[$(date -Is)] Compactando ..."
tar -czf "${ARTIFACT}.tmp" -C "$STAGING" data || fail "tar falhou"

echo "[$(date -Is)] Verificando integridade ..."
tar -tzf "${ARTIFACT}.tmp" >/dev/null || fail "artefato corrompido (tar -t)"

mv "${ARTIFACT}.tmp" "$ARTIFACT"
( cd "$DEST" && sha256sum "$(basename "$ARTIFACT")" > "$(basename "$ARTIFACT").sha256" )
chown -R homelab:homelab "$DEST_ROOT" 2>/dev/null || true
rm -rf "${STAGING:?}/data"

SIZE="$(stat -c%s "$ARTIFACT")"
echo "[$(date -Is)] OK: ${ARTIFACT} ($(numfmt --to=iec "$SIZE" 2>/dev/null || echo "$SIZE bytes"))"

# ── Retenção (artefatos antigos + subpastas mensais vazias) ─────────────────
find "$DEST_ROOT" -mindepth 2 -maxdepth 2 -name 'couchdb-*.tar.gz' -mtime "+${RETENTION_DAYS}" -print -delete
find "$DEST_ROOT" -mindepth 2 -maxdepth 2 -name 'couchdb-*.tar.gz.sha256' -mtime "+${RETENTION_DAYS}" -delete
find "$DEST_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20??-??' -empty -print -delete

write_metrics 1 "$(( $(date +%s) - START ))" "$SIZE" "$(date +%s)"
echo "[$(date -Is)] Concluído em $(( $(date +%s) - START ))s. Retenção: ${RETENTION_DAYS} dias."
