# Firewall do host (UFW + DOCKER-USER)

Endurecimento feito em 2026-07-07. Duas camadas complementares:

## Camada 1 — UFW (serviços do HOST)

O ufw protege o que escuta direto no host (SSH, Samba). Política:
`deny incoming / allow outgoing / deny routed`, com exceções:

| Regra | Motivo |
|---|---|
| `allow in on tailscale0` | tailnet é autenticada (WireGuard) — confiança total |
| `22/tcp from <SUBNET_LAN>` | SSH só da LAN (tailnet já coberta acima) |
| `445,139/tcp + 137:138/udp from LAN` | Samba (share `Deletados`) |
| `80,443/tcp from LAN` | proxies internos do NPM |

```bash
sudo ufw status verbose      # inspecionar
sudo ufw disable             # desligar tudo (emergência)
```

⚠️ ufw NÃO protege portas publicadas por containers (o Docker escreve no
iptables antes dele). Para isso existe a camada 2.

## Camada 2 — DOCKER-USER (portas publicadas por CONTAINERS)

`docker-user-rules.sh` programa a chain `DOCKER-USER` (a única que o Docker
respeita): tráfego da rede física (wlan0/eth0) só alcança containers nas
portas **80/443** (NPM). Qualquer outra porta publicada — inclusive por
engano num compose futuro — fica invisível pra LAN.

- Fonte canônica: esta pasta. Editar e re-rodar `sudo ./install.sh`.
- Instalado em: `/usr/local/bin/docker-user-rules.sh` + `docker-user.service`
  (roda no boot, depois do docker; `BindsTo` re-executa se o docker reiniciar).
- Não afeta: tráfego entre containers, saída de containers, loopback, tailnet.

```bash
sudo iptables -nL DOCKER-USER --line-numbers   # inspecionar
sudo systemctl status docker-user.service      # estado
sudo iptables -F DOCKER-USER && sudo iptables -A DOCKER-USER -j RETURN  # desativar (emergência)
```

## Convenção pra stacks novos (Nextcloud incluso)

Publicar porta SEMPRE em `127.0.0.1:` (ou sem `ports:`). Acesso externo:
Cloudflare Tunnel (público) ou `tailscale serve` (pessoal). Se um dia uma
porta de container precisar ser alcançável da LAN, adicionar a porta em
`ALLOWED_TCP_PORTS` no script E documentar aqui o porquê.

## Acessos após o endurecimento (via tailnet)

| Serviço | URL |
|---|---|
| CouchDB (Obsidian) | https://sua-tailnet.ts.net:8443 |
| Grafana | https://sua-tailnet.ts.net:8444 |
| NPM admin | https://sua-tailnet.ts.net:8445 |
| Portainer | https://sua-tailnet.ts.net:8446 |

Postgres: sem porta publicada — admin via `docker exec -it postgres_homelab psql -U admin -d homelab_global`.
