# CouchDB — Obsidian Self-hosted LiveSync

Banco CouchDB para sincronizar o Obsidian (desktop + mobile) via plugin
**Self-hosted LiveSync**, acessível **apenas pela tailnet** com HTTPS.

## Arquitetura

```
Obsidian (qualquer device na tailnet)
   │  https://sua-tailnet.ts.net:8443   (cert válido, auto-renovado pelo Tailscale)
   ▼
tailscale serve  ──►  127.0.0.1:5984  ──►  container couchdb
```

- CouchDB amarrado em `127.0.0.1:5984` — **nunca** exposto na LAN nem na internet.
- Quem faz HTTPS é o `tailscale serve` (porta 8443). Proxy reverso da LAN não
  é tocado.
- Criptografia E2E ativada no LiveSync → o servidor só vê dados cifrados.

## Setup

```bash
cp .env.example .env
chmod 600 .env
# edite .env com usuário/senha fortes e únicos
docker compose up -d
```

Credenciais do CouchDB ficam em `.env` (modo 600). **NÃO commitar.**

## Pré-requisito manual (uma vez)

Habilitar **HTTPS Certificates** no admin console do Tailscale:
<https://login.tailscale.com/admin/dns> → seção *HTTPS Certificates* → **Enable**.
(MagicDNS precisa estar ligado.)

Depois, ativar o serve:
```bash
sudo tailscale serve --bg --https=8443 http://127.0.0.1:5984
sudo tailscale serve status   # deve listar https://sua-tailnet.ts.net:8443
```

## Operação

```bash
docker compose up -d        # subir
docker compose logs -f      # logs
docker compose down         # parar (dados persistem em ./data)
```

DBs de sistema (`_users`, `_replicator`, `_global_changes`) já criados
automaticamente pelo CouchDB.

## Backup (automatizado)

Backup **a quente** (sem downtime — os `.couch` são append-only) via systemd timer,
diário, com retenção configurável (padrão: 14 dias).

- **Fonte canônica: `./backup/`** (scripts + units versionados junto do stack).
  Editar aqui e re-instalar com `sudo ./backup/install.sh` — o install copia
  para `/usr/local/bin` e `/etc/systemd/system` (cópia, não symlink, para
  root nunca executar arquivo gravável pelo usuário).
- Units: `couchdb-backup.{service,timer}` + `couchdb-backup-alert.service` (OnFailure)
- Destino: `~/backups/couchdb/AAAA-MM/` (subpasta mensal — ajustar a var
  `DEST_ROOT` no script conforme seu ambiente, ex.: HDD dedicado ou storage externo)
- Artefatos: `couchdb-AAAAMMDD-HHMMSS.tar.gz` + `.sha256` (verificar com
  `sha256sum -c` dentro da subpasta mensal)

Como o LiveSync usa E2E, o conteúdo dentro do backup já está cifrado.

### Consultar
```bash
journalctl -u couchdb-backup.service            # histórico
systemctl status couchdb-backup.service         # resultado da última rodada
systemctl list-timers couchdb-backup.timer      # próxima/última execução
ls -lh ~/backups/couchdb/*/                     # artefatos (por mês)
```

### Alertas (Discord via Alertmanager)
- **Push imediato** em falha: `OnFailure=` → `couchdb-backup-alert.sh` → API do Alertmanager.
- **Dead man's switch**: o script publica métricas no node-exporter
  (`/var/lib/node_exporter/textfile/couchdb_backup.prom`); regras no Prometheus
  (alerta se ficar tempo demais sem sucesso, e se a última execução falhou) → Discord.

### Rodar backup manual
```bash
sudo systemctl start couchdb-backup.service
```

### Restore (⚠️ ação de desastre, não rotina)
Restaurar rebobina TODOS os devices pro instante do backup; ao reconectarem, o
LiveSync re-sincroniza e a resolução de conflito dele pode gerar marcadores/duplicatas.
```bash
cd couchdb/
docker compose down
sudo rm -rf data && sudo mkdir data
sudo tar xzf ~/backups/couchdb/AAAA-MM/couchdb-AAAAMMDD-HHMMSS.tar.gz -C /tmp
sudo cp -a /tmp/data/. data/
sudo chown -R 5984:5984 data
docker compose up -d
```
Depois, nos devices, deixe o LiveSync re-sincronizar e resolva eventuais conflitos.
