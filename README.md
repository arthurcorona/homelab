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
![n8n](https://img.shields.io/badge/-n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)

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

> **Nota:** Este repositório não contém arquivos `.env` ou senhas reais.

Para replicar este ambiente, é necessário criar um arquivo `.env` em cada diretório de serviço com as seguintes variáveis:
* `POSTGRES_USER`
* `POSTGRES_PASSWORD`
* `N8N_BASIC_AUTH_PASSWORD` (se aplicável)
* `GRAFANA_ADMIN_PASSWORD`

---

## 🗺️ Mapa de Portas (Port Map)

Visão geral dos serviços expostos e suas respectivas portas no Docker Host.

| Serviço | Stack | Porta Interna | **Porta Host** | Acesso (Exemplo) |
| :--- | :--- | :--- | :--- | :--- |
| **Nginx Proxy Manager** | Gateway | 80, 443 | **80, 443** | `https://seu-dominio.com` |
| **Nginx Admin** | Gateway | 81 | **81** | `http://<IP_LOCAL>:81` |
| **n8n Workflow** | Automation | 5678 | **5678** | `https://n8n.seu-dominio.com` |
| **Postgres (Main)** | Database | 5432 | **5432** | `jdbc:postgresql://<IP_LOCAL>:5432` |
| **Grafana** | Monitoring | 3000 | **3000** | `http://<IP_LOCAL>:3000` |
| **Prometheus** | Monitoring | 9090 | **9090** | `http://<IP_LOCAL>:9090` |
| **Alert Manager** | Monitoring | 9093 | **9093** | `http://<IP_LOCAL>:9093` |
| **Portainer** | Management | 9000 | **9000** | `http://<IP_LOCAL>:9000` |

---

## 🏗️ Arquitetura e Estrutura

A organização segue o padrão de microserviços, onde cada stack possui seu próprio diretório e `docker-compose.yml` independente.

```plaintext
/home/user/homelab/
├── npm/                  # 🛡️ Nginx Proxy Manager (Reverse Proxy & SSL)
│   ├── data/
│   ├── letsencrypt/
│   └── docker-compose.yml
│
├── postgres/             # 🐘 Banco de Dados Compartilhado (Dev & Apps)
│   ├── data/
│   └── docker-compose.yml
│
├── n8n/                  # 🤖 Automação Low-Code
│   ├── volumes/
│   │   ├── db_data/      # Postgres dedicado ao n8n
│   │   └── n8n_data/     # Dados de Workflows
│   └── docker-compose.yml
│
├── monitoring/           # 👁️ Observabilidade (Prometheus Stack)
│   ├── grafana/
│   ├── prometheus/
│   └── docker-compose.yml
│
└── scripts/              # ⚙️ Manutenção e Utilitários
    └── fan_control.py
```
## Detalhes das Stacks

### 1. Proxy Reverso (Nginx Proxy Manager)
- **Função:** Recebe requisições externas (Internet) e distribui para containers internos, gerenciando certificados SSL (HTTPS)
- **Rede Docker:** `proxy-net` (Externa)
- **Status:** 🟢 Ativo

### 2. Automação (n8n)
- **Função:** Motor de workflows com banco Postgres dedicado (`n8n-postgres`)
- **Autenticação:** Owner Account (Email/Senha)
- **Dependência:** Conectado à rede `proxy-net` para acesso via Nginx

### 3. Monitoramento (Big Brother)
Stack de observabilidade com:
- **Prometheus:** Coleta métricas
- **Node Exporter:** Monitora hardware (CPU/RAM/Temperatura)
- **Grafana:** Visualização de dados

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