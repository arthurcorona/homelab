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

# Cloud Server com Nextcloud, Docker e Cloudflare Tunnel

Este projeto tem como objetivo a criação de um servidor de nuvem pessoal utilizando [Nextcloud](https://nextcloud.com/), de forma segura e acessível de qualquer lugar. A arquitetura utiliza [Docker](https://www.docker.com/) para containerizar a aplicação, [Nginx](https://www.nginx.com/) como proxy reverso e [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) para expor o serviço à internet de forma segura, sem a necessidade de abrir portas no seu roteador ou firewall.

## Arquitetura da Solução

O fluxo de uma requisição do usuário até a sua instância Nextcloud funcionará da seguinte maneira:

Usuário → Internet → Rede Cloudflare → Cloudflared Tunnel → Seu Servidor (Docker) → Nginx (Container) → Nextcloud (Container)

Essa abordagem garante que todo o tráfego seja criptografado e passe pela infraestrutura da Cloudflare antes de chegar ao seu servidor.

## Pré-requisitos

Antes de começar, garanta que você tenha:

-   Um domínio registrado (ex: meudominio.com).
-   Uma conta gratuita na [Cloudflare](https://www.cloudflare.com/).
-   Um servidor Linux (pode ser um Raspberry Pi, um VPS ou uma máquina local) com acesso sudo.
-   Docker e Docker Compose instalados no servidor.

---

## Passo a Passo da Instalação

### 1. Configuração Inicial do Domínio na Cloudflare

O primeiro passo é delegar a gestão do DNS do seu domínio para a Cloudflare.

1.  Acesse o painel da *Cloudflare* e clique em "Adicionar site". Insira seu domínio.
2.  A Cloudflare irá escanear seus registros DNS e, em seguida, fornecerá dois ou mais *Nameservers* (Servidores de Nomes).
3.  Acesse o painel de controle do seu provedor de domínio (onde você o registrou) e substitua os nameservers atuais pelos que a Cloudflare forneceu.

> *Nota:* A propagação de DNS pode levar de alguns minutos a várias horas.

### 2. Preparação do Ambiente no Servidor

#### 2.1. Instalação do Docker

Se o Docker ainda não estiver instalado, utilize o script oficial para uma instalação rápida.

bash
```bash
# Baixar e executar o script de instalação do Docker
curl -sSL https://get.docker.com | sh
# Adicionar seu usuário ao grupo do Docker para executar comandos sem 'sudo'
# (Você precisará fazer logout e login novamente para que isso tenha efeito)
sudo usermod -aG docker ${USER}

# Instalar o plugin do Docker Compose
sudo apt-get update
sudo apt-get install -y docker-compose-plugin
```
### 2.2. Estrutura de Arquivos

```bash
mkdir -p nextcloud-server/nginx/conf.d
cd nextcloud-server
```

<p>A estrutura final ficará:</p>

```bash
nextcloud-server/
├── docker-compose.yml
└── nginx/
    └── conf.d/
        └── nextcloud.conf
```
## 3. Configuração dos Serviços Docker e Nginx

### 3.1 Criando o docker-compose.yml

```bash
sudo nano docker-compose.yml
```

Cole o arquivo .yml que está no repositório, fazendo as alterações necessárias.

### 3.2 Criando o arquivo nginx/conf.d/nextcloud.config

Este arquivo configura o Nginx que roda dentro do Docker, instruindo-o a receber requisições e encaminhá-las para o serviço do Nextcloud (PHP-FPM).

```bash
sudo nano nginx/conf.d/nextcloud.conf 
```

Cole o arquivo nextcloud.config que está no repositório, fazendo as alterações necessárias.

## 4.  Instalação e Configuração do Cloudflare Tunnel

Para instalar:
```bash
# Para x86_64, use 'cloudflared-linux-amd64'
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared

sudo chmod +x /usr/local/bin/cloudflared
```

### 4.1 Autenticação e criação do túnel
Faça o login na sua conta Cloudflare:

```bash
cloudflared tunnel login
``` 

Depois de acessar o link do output do comando acima e autorizar seu domínio, crie o túnel:

```bash
cloudflared tunnel create nextcloud-tunnel
```

<p>Anote o UUID do output!</p>

Crie uma rota DNS:

```bash
cloudflared tunnel route dns nextcloud-tunnel seudominio.com
```

### 4.2 Configuraçao do cloudflared
Agora iremos configurar o serviço cloudflared. 

```bash 
#obs: o arquivo irá ficar no diretório etc
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

Cole o seguinte bloco, substituindo o UUID e o path.

```bash 
tunnel: seuUUID 
credentials-file: /etc/cloudflared/seuUUID.json

ingress:
  - hostname: seudominio.com
    service: http://localhost:8080
  - service: http_status:404
```

Agora, instale e inicie o serviço cloudflared:

```bash 
sudo cloudflared service install
sudo systemctl start cloudflared

sudo systemctl status cloudflared
```

## 5. Inicialização e configuração final

Suba os containers e aguarde alguns minutos (no diretório que há o arquivo docker-compose.yml)

```bash 
sudo docker-compose up -d
```

### 5.1 Configurar o config.php

É necessário informar ao nextcloud que ele está rodando através de um proxy reverso

```bash
#acesse o sh no container nextcloud 
sudo docker-compose exec --user www-data app sh
```
No shell do container, acesse o config pelo vi

```bash
vi config/config.php
```

Cole esse arquivo com as modificações necessárias:

```bash
<?php
$CONFIG = array (
  #gerados automaticamente
  'instanceid' => '...',
  'passwordsalt' => '...',
  'secret' => '...',
  'installed' => true,
  'version' => '...', 

  'trusted_domains' => 
  array (
    0 => 'localhost',
    1 => 'seudominio.com',
  ),

  'overwrite.cli.url' => 'https://seudominio.com',
  'overwritehost' => 'seudominio.com',
  'overwriteprotocol' => 'https', 

  'dbtype' => 'mysql',
  'dbname' => 'nextcloud',
  'dbhost' => 'db',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'password', #mesma do docker-compose.yml

  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
  ),
  
  'datadirectory' => '/var/www/html/data',
);
```

Após salvar o arquivo e sair do shell, você pode acessar o https://seudominio.com pelo navegador, que estará funcionando.