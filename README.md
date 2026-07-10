<p align="center">
  <a href="https://github.com/arthurcorona">
    <img alt="GitHub" width="35" src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white">
  </a>
  <a href="https://www.linkedin.com/in/arthur-corona-32a155216/">
    <img alt="LinkedIn" width="35" src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white">
  </a>
</p>

# 🏠 Corona Homelab

![Raspberry Pi](https://img.shields.io/badge/-Raspberry_Pi-C51A4A?style=for-the-badge&logo=Raspberry-Pi)
![Docker](https://img.shields.io/badge/-Docker-2496ED?style=for-the-badge&logo=Docker&logoColor=white)
![Linux](https://img.shields.io/badge/-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Nginx](https://img.shields.io/badge/-Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Nextcloud](https://img.shields.io/badge/-Nextcloud-0082C9?style=for-the-badge&logo=nextcloud&logoColor=white)
![CouchDB](https://img.shields.io/badge/-CouchDB-E42528?style=for-the-badge&logo=apachecouchdb&logoColor=white)
![Cloudflare](https://img.shields.io/badge/-Cloudflare_Tunnel-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Tailscale](https://img.shields.io/badge/-Tailscale-242424?style=for-the-badge&logo=tailscale&logoColor=white)

Bem-vindo ao repositório de Infraestrutura do meu **Homelab**. Este repositório contém a configuração de **Infrastructure as Code** (IaC) utilizada para provisionar e manter meu servidor doméstico.

O objetivo deste ambiente é servir como laboratório de estudos para **DevOps, Automação, Cibersegurança e Redes**, hospedando serviços críticos de forma self-hosted.

---

## 🖥️ Especificações do Hardware

O servidor roda em um Single Board Computer com boot nativo via USB 3.0 para maior performance e durabilidade.

| Componente | Especificação |
| :--- | :--- |
| **Host** | Raspberry Pi 4 Model B |
| **Armazenamento** | SSD (Boot Nativo via USB 3.0) |
| **OS** | Raspberry Pi OS (Debian Bookworm) |
| **Acesso** | SSH & VPN (Tailscale) |

---

## 🔐 Segurança e Credenciais

> **Nota:** Este repositório não contém arquivos `.env` ou senhas reais — os
> composes referenciam variáveis (`${VAR}`) resolvidas por um `.env` local.

**Padrão adotado:** cada stack tem seu próprio `.env` (com `chmod 600`, fora do
git — ver `.gitignore`) e um `.env.example` versionado documentando o contrato.
Senhas nunca são reutilizadas entre serviços.

| Stack | `.env` local (600) | Variáveis (ver `.env.example`) |
| :--- | :--- | :--- |
| `postgres/` | ✅ | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `big_brother/` | ✅ | `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD` (só 1º boot) |
| `couchdb/` | ✅ | `COUCHDB_USER`, `COUCHDB_PASSWORD` |
| `nextcloud/` | ✅ | `NEXTCLOUD_DB_PASSWORD`, `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD` |

**Exceção documentada:** `big_brother/alertmanager/alertmanager.yml` contém o
webhook do Discord e o Alertmanager não interpola variáveis de ambiente — a
proteção lá é permissão de arquivo (`chmod 600`, dono = uid do container).
O arquivo versionado aqui usa placeholder.

---

## 🗺️ Mapa de Portas (Port Map)

**Modelo de exposição:** nada é público por porta. Acesso público = Cloudflare
Tunnel (conexão de saída — zero port-forward no roteador). Acesso pessoal/admin
= tailnet (`tailscale serve`). A LAN só enxerga o proxy e o SSH; todo o resto
vive em `127.0.0.1` (loopback), protegido por UFW + chain `DOCKER-USER`
(ver `firewall/`).

| Serviço | Stack | Bind no Host | Acesso |
| :--- | :--- | :--- | :--- |
| **Nginx Proxy Manager** | Gateway | `0.0.0.0:80/443` | LAN (proxies internos) |
| **NPM Admin (81)** | Gateway | `127.0.0.1:81` | tailnet `:8445` |
| **Postgres (Main)** | Database | *(sem porta)* | só rede docker `proxy-net`; admin via `docker exec` |
| **Grafana** | Monitoring | `127.0.0.1:3000` | tailnet `:8444` |
| **Prometheus** | Monitoring | `127.0.0.1:9090` | local (sem auth ⇒ nunca expor) |
| **Alertmanager** | Monitoring | `127.0.0.1:9093` | local (alertas saem p/ Discord) |
| **cAdvisor / node-exporter** | Monitoring | `127.0.0.1:8080/9100` | só o Prometheus consome |
| **Portainer** | Management | `127.0.0.1:9443` | tailnet `:8446` |
| **Nextcloud** | Cloud pessoal | `127.0.0.1:8082` | `https://cloud.seudominio.com` (Cloudflare Tunnel) |
| **CouchDB** | Sync (Obsidian) | `127.0.0.1:5984` | tailnet `:8443` (`tailscale serve`) |

---

## 🏗️ Arquitetura e Estrutura

A organização segue o padrão de microserviços, onde cada stack possui seu próprio diretório e `docker-compose.yml` independente.

```plaintext
/home/user/homelab/
├── nginx/                # 🛡️ Nginx Proxy Manager (Reverse Proxy & SSL)
│   └── docker-compose.yml         # data/ e letsencrypt/ não versionados
│
├── postgres/             # 🐘 Banco Compartilhado (role dedicado por app)
│   ├── docker-compose.yml         # sem porta publicada
│   └── .env.example
│
├── big_brother/          # 👁️ Observabilidade (Prometheus Stack)
│   ├── prometheus/                # prometheus.yml + alerts.yml
│   ├── alertmanager/              # rota → Discord (webhook via placeholder)
│   └── docker-compose.yml
│
├── couchdb/              # 🔄 CouchDB (Obsidian Self-hosted LiveSync)
│   ├── backup/           # scripts + systemd units (timer + alerta + métricas)
│   ├── etc/local.ini
│   └── docker-compose.yml
│
├── nextcloud/            # ☁️ Nuvem Privada (Nextcloud + Redis + cron)
│   └── docker-compose.yml         # html/ e dados não versionados
│
└── firewall/             # 🔥 Contenção Docker×UFW (chain DOCKER-USER)
    ├── docker-user-rules.sh       # fonte canônica das regras
    ├── docker-user.service        # reaplica no boot (systemd)
    └── install.sh
```
## Detalhes das Stacks

### 1. Proxy Reverso (Nginx Proxy Manager)
- **Função:** Recebe requisições externas (Internet) e distribui para containers internos, gerenciando certificados SSL (HTTPS)
- **Rede Docker:** `proxy-net` (Externa)
- **Status:** 🟢 Ativo

### 2. Firewall em camadas (UFW + DOCKER-USER)
- **Problema que resolve:** o Docker escreve regras no iptables ANTES do UFW —
  portas publicadas por containers ignoram o firewall do host.
- **Solução:** binds em `127.0.0.1` por padrão + UFW pros serviços do host +
  regras na chain `DOCKER-USER` (a única que o Docker respeita) limitando
  tráfego da LAN aos containers a 80/443. Erro de compose futuro fica contido.
- **Persistência:** unit systemd reaplica as regras a cada boot/restart do Docker.

### 3. Monitoramento (Big Brother)
Stack de observabilidade com:
- **Prometheus:** Coleta métricas
- **Node Exporter:** Monitora hardware (CPU/RAM/Temperatura)
- **Grafana:** Visualização de dados

### 4. Nuvem Privada (Nextcloud)
- **Função:** Cloud storage pessoal (arquivos, fotos, contatos, calendário) via app mobile/desktop
- **Stack:** Nextcloud (imagem oficial pinada) + Redis (locking/cache) + container de cron
- **Banco:** Postgres compartilhado, com role/database dedicados (`nextcloud`)
- **Exposição:** só `127.0.0.1`, publicado via **Cloudflare Tunnel** — nenhuma porta aberta no roteador
- **Dados:** em disco separado do disco de sistema (bind mount)

### 5. Sincronização (CouchDB + Obsidian LiveSync)
- **Função:** backend de sincronização E2E-criptografada para o plugin Obsidian Self-hosted LiveSync
- **Exposição:** só `127.0.0.1`, publicado **apenas na tailnet** via `tailscale serve` (HTTPS)
- **Backup:** systemd timer diário (backup a quente + retenção + verificação sha256), com alerta de falha via Alertmanager/Discord — ver `couchdb/README.md`

---

## 📝 Cheatsheet e Comandos Úteis

### Docker
```bash
# Verificar containers rodando
docker ps

# Verificar logs de um container específico
docker logs -f container_name

# Reiniciar uma stack (dentro da pasta)
docker compose restart

## Banco de Dados (PostgreSQL)

```bash
# Conectar no banco como 'admin'
docker exec -it postgres_homelab psql -U admin -d database_name