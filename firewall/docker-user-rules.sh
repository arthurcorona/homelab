#!/usr/bin/env bash
# Contenção na chain DOCKER-USER: portas publicadas por containers só são
# alcançáveis da rede física (LAN) nas portas 80/443 (NPM). O resto é DROP.
# Motivo: o Docker escreve regras iptables ANTES do ufw — sem isso, um
# compose que publique "0.0.0.0:x" por engano fica exposto pra LAN inteira.
#
# Cobre wlan0 E eth0 (hoje o Pi usa WiFi; se migrar pra cabo, continua valendo).
# Tráfego entre containers e saída de containers não passam por estas regras
# de interface física — não são afetados.
#
# Fonte canônica: /home/homelab/docker/firewall/ — editar aqui e re-rodar install.sh
set -euo pipefail

PHYS_IFACES=(wlan0 eth0)
ALLOWED_TCP_PORTS=(80 443)

apply() {  # $1 = iptables | ip6tables
  local ipt="$1"
  "$ipt" -N DOCKER-USER 2>/dev/null || true
  "$ipt" -F DOCKER-USER
  # respostas de conexões já estabelecidas (ex.: saída de containers) passam
  "$ipt" -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
  for IF in "${PHYS_IFACES[@]}"; do
    for PORT in "${ALLOWED_TCP_PORTS[@]}"; do
      "$ipt" -A DOCKER-USER -i "$IF" -p tcp -m conntrack --ctorigdstport "$PORT" -j RETURN
    done
    "$ipt" -A DOCKER-USER -i "$IF" -m conntrack --ctstate NEW -j DROP
  done
  "$ipt" -A DOCKER-USER -j RETURN
}

apply iptables
# só aplica no ip6tables se o Docker tiver criado a infra v6
if ip6tables -nL FORWARD >/dev/null 2>&1; then
  apply ip6tables
fi

echo "DOCKER-USER aplicado: LAN só alcança containers em ${ALLOWED_TCP_PORTS[*]}/tcp."
