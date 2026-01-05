<p align="center">
  <a href="https://github.com/arthurcorona">
    <img alt="Corona" width="25" src="./images/logo_github.png">
  </a>
  <a href="https://www.linkedin.com/in/arthur-corona-32a155216/">
    <img alt="LinkedIn" width="25" src="./images/logo_linkedin.png">
  </a>
  <a href="https://www.x.com/imarthurcorona">
    <img alt="x" width="25" src="./images/logo_x.png">
  </a>
</p>

# 🏠 Corona Server

![Raspberry Pi](https://img.shields.io/badge/-Raspberry_Pi-C51A4A?style=for-the-badge&logo=Raspberry-Pi)
![Docker](https://img.shields.io/badge/-Docker-2496ED?style=for-the-badge&logo=Docker&logoColor=white)
![Linux](https://img.shields.io/badge/-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Status](https://img.shields.io/badge/Status-Operational-success?style=for-the-badge)

Bem-vindo ao repositório central do meu **Homelab**. Este repositório contém toda a configuração de "Infrastructure as Code" (IaC) utilizada para manter meu servidor doméstico rodando.

O objetivo deste ambiente é servir como laboratório de estudos para **DevOps, Cibersegurança e Redes**, além de hospedar serviços pessoais (Nuvem, Mídia, Monitoramento).

---

## 🖥️ Especificações do Hardware

O servidor roda em um Single Board Computer com boot nativo via USB 3.0 (sem cartão SD) para maior performance e durabilidade.

| Componente | Especificação |
| :--- | :--- |
| **Host** | Raspberry Pi 4 Model B |
| **Armazenamento** | SSD (Boot Nativo via USB 3.0) |
| **OS** | Raspberry Pi OS (Debian Bookworm) |
| **Refrigeração** | Active Cooling (Script Python customizado) |
| **Rede** | IP Estático / Acesso Remoto via Tailscale & SSH |

---

## 🏗️ Arquitetura e Serviços

Todos os serviços são containerizados utilizando **Docker** e orquestrados via **Docker Compose**. Abaixo está a lista dos serviços ativos. Clique no nome do serviço para ver o **README específico** com detalhes de configuração e instalação.

| Serviço | Categoria | Descrição | Stack |
| :--- | :--- | :--- | :--- |
| **[Monitoramento](./monitoring)** | Observabilidade | Stack completa para métricas de hardware e containers. | Prometheus, Grafana, Node Exporter, cAdvisor |
| **[Nuvem Pessoal](./cloud)** | Armazenamento | Servidor de arquivos e sincronização de dados. | *(Nextcloud/Filebrowser - ajuste aqui)* |
<!--| **[VPN / Acesso](./vpn)** | Rede | Acesso seguro remoto à rede local. | Tailscale / Wireguard |
| **[Automação](./scripts)** | Scripts | Scripts de manutenção do sistema. | Python, Bash |-->

---

## 📂 Estrutura de Diretórios

A organização do repositório segue a lógica de separar cada stack em sua própria pasta com seu respectivo `docker-compose.yml` e documentação.

```plaintext
.
├── cloud/               # Configurações da Nuvem Pessoal
│   ├── docker-compose.yml
│   ├── nginx
│   |    └── conf.d
│   │         └── nextcloud.conf
│   └── README.md        # 📄 Detalhes específicos da Nuvem
├── big_brother/          # Stack de Monitoramento
│   ├── grafana/
│   ├── prometheus/
│   ├── docker-compose.yml
│   └── README.md        # 📄 Detalhes de Dashboards e Alerts
├── scripts/             # Scripts utilitários (Fan Control, Backups)
│   ├── fan_control.py   # Controle inteligente da ventoinha
│   └── README.md
└── README.md            # (Você está aqui)