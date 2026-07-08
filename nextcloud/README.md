# Nextcloud — Nuvem Privada

Nextcloud 33 (imagem oficial pinada) + Redis + cron. Dados num disco dedicado
(separado do disco de sistema).

## Arquitetura

```
celular/navegador (qualquer lugar)
   │  https://cloud.seudominio.com
   ▼
Cloudflare (TLS na borda, tunnel — nenhuma porta aberta no roteador)
   ▼
cloudflared no host  ──►  127.0.0.1:8082  ──►  container nextcloud
                                                 ├─ postgres_homelab (proxy-net, role dedicado `nextcloud`)
                                                 ├─ nextcloud-redis (file locking / cache)
                                                 └─ dados: /mnt/dados-2tb/nextcloud-data (disco dedicado)
```

- App (`./html`) fica no SSD (rápido); DADOS ficam num disco dedicado via bind mount.
- Porta só em `127.0.0.1:8082` — LAN não alcança (e o firewall bloquearia de
  qualquer forma; ver `../firewall/README.md`).
- Credenciais em `.env` (600, nunca commitado — veja `.env.example`): senha do
  banco e do usuário admin.

## Setup

```bash
cp .env.example .env
chmod 600 .env
# edite .env com senhas fortes e únicas
docker compose up -d
```

## Operação

```bash
docker compose up -d / down / logs -f
docker exec -u 33 nextcloud php occ <comando>   # occ sempre como uid 33 (www-data)
docker exec -u 33 nextcloud php occ status
```

## Uploads grandes

Cloudflare (free) limita ~100MB por request. Os clientes Nextcloud fazem
upload em **chunks de 10MB** por padrão — arquivos grandes funcionam.
Se upload grande falhar: conferir se o chunking não foi desativado
(`occ config:app:get files max_chunk_size`).

## Discos

- App no SSD do sistema; dados num disco dedicado, montado por `LABEL=` no
  fstab com `noatime,nofail` (`nofail` é obrigatório: HD externo ausente não
  pode travar o boot).
- Se aparecerem resets USB (UAS) sob carga nos logs do kernel: aplicar quirk
  `usb-storage.quirks=<vid>:<pid>:u` no cmdline (desliga UAS) e/ou trocar
  cabo/fonte.
- Espelho diário para um segundo disco (backup) é recomendado — ver padrão em
  `../couchdb/backup/` como referência de systemd timer + métricas + alerta.

## Backup / restore

Dump do banco:
```bash
docker exec postgres_homelab pg_dump -U <role_nextcloud> nextcloud > nextcloud.sql
```
Dados: espelho/rsync do bind mount de dados (fora do escopo deste README —
seguir o padrão de `../couchdb/backup/`).

## Hardening aplicado / recomendado

- [x] Role de banco dedicado sem privilégios globais; `PUBLIC` revogado.
- [x] Redis locking, `default_phone_region` configurado, background jobs via
      cron container, `maintenance_window_start` fora do horário de uso.
- [ ] 2FA no admin (fazer no primeiro login!), checar `/settings/admin/overview`.
