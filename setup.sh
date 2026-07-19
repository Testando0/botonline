#!/bin/bash

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
C='\033[1;36m'
W='\033[1;37m'
X='\033[0m'

clear
echo "${C}"
echo "╔════════════════════════════════════════╗"
echo "║        🤖  BOT INSTALLER  —  24H       ║"
echo "╚════════════════════════════════════════╝"
echo "${X}"

# ── 1. Bot já está na máquina ou precisa clonar? ──────────────────────────────
echo "${W}O bot já está baixado nesta máquina?${X}"
echo "  ${G}[1]${X} Sim, já está aqui (informar pasta)"
echo "  ${G}[2]${X} Não, quero clonar do GitHub"
echo ""
read -p "Escolha (1 ou 2): " OPCAO </dev/tty

BOT_DIR=""

if [ "$OPCAO" = "1" ]; then
  echo ""
  read -p "📁 Nome da pasta do bot: " BOT_DIR </dev/tty
  if [ -z "$BOT_DIR" ] || [ ! -d "$BOT_DIR" ]; then
    echo "${R}[ ERRO ] Pasta '$BOT_DIR' não encontrada.${X}"
    exit 1
  fi
  echo "${G}[ OK ] Pasta encontrada: $BOT_DIR${X}"

elif [ "$OPCAO" = "2" ]; then
  echo ""
  read -p "🔗 Link do GitHub: " REPO_URL </dev/tty
  if [ -z "$REPO_URL" ]; then
    echo "${R}[ ERRO ] Nenhum link informado.${X}"
    exit 1
  fi
  BOT_DIR=$(basename "$REPO_URL" .git)
  echo "${Y}[ INFO ] Clonando repositório...${X}"
  git clone "$REPO_URL" "$BOT_DIR"
  if [ $? -ne 0 ]; then
    echo "${R}[ ERRO ] Falha ao clonar. Verifique o link e tente novamente.${X}"
    exit 1
  fi
  echo "${G}[ OK ] Repositório clonado em: $BOT_DIR${X}"

else
  echo "${R}[ ERRO ] Opção inválida.${X}"
  exit 1
fi

sleep 0.5

# ── 2. Ler o package.json para descobrir o comando de start ───────────────────
echo ""
echo "${Y}[ INFO ] Lendo package.json...${X}"
PKG="$BOT_DIR/package.json"

if [ ! -f "$PKG" ]; then
  echo "${R}[ AVISO ] package.json não encontrado.${X}"
  read -p "▶️  Digite o comando para iniciar o bot: " START_CMD </dev/tty
else
  START_CMD=$(node -e "
    try {
      const p = require('./$PKG');
      const s = p.scripts && p.scripts.start;
      if (s) { console.log(s); }
      else { console.log('node index.js'); }
    } catch(e) { console.log('node index.js'); }
  " 2>/dev/null)
  echo "${G}[ OK ] Comando detectado: ${W}$START_CMD${X}"
fi

sleep 0.5

# ── 3. Instalar dependências ──────────────────────────────────────────────────
echo ""
echo "${Y}[ INFO ] Instalando dependências...${X}"
cd "$BOT_DIR"

if [ -f "package.json" ]; then
  if command -v yarn &>/dev/null; then
    yarn install --silent 2>&1 | tail -3
  else
    npm install --silent 2>&1 | tail -3
  fi
  echo "${G}[ OK ] Dependências instaladas!${X}"
fi

cd ..
sleep 0.5

# ── 4. Criar servidor de uptime ───────────────────────────────────────────────
cat > UptimeServer.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';
http.createServer((req, res) => {
  const f = path.join(__dirname, 'index.html');
  fs.readFile(f, (err, data) => {
    if (err) { res.writeHead(500); res.end('erro'); return; }
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(data);
  });
}).listen(PORT, HOST, () => {
  console.log(`\n✅ Uptime server em ${HOST}:${PORT}`);
  console.log('📡 Adicione a URL deste Replit no UptimeRobot!\n');
});
EOF

# ── 5. Criar script de loop (run.sh) ─────────────────────────────────────────
cat > run.sh << RUNEOF
#!/bin/bash
G='\033[1;32m'
Y='\033[1;33m'
X='\033[0m'

node UptimeServer.js &

cd ${BOT_DIR}

while :
do
  echo "\${G}▶ Iniciando bot...${X}"
  ${START_CMD} </dev/tty
  echo "\${Y}⚠️  Bot encerrou. Reiniciando em 3s...${X}"
  sleep 3
done
RUNEOF

chmod +x run.sh

# ── 6. Iniciar bot e aguardar conexão ─────────────────────────────────────────
echo ""
echo "${C}════════════════════════════════════════════${X}"
echo "${W} Iniciando o bot e aguardando conexão...${X}"
echo "${C}════════════════════════════════════════════${X}"
echo ""

LOG_FILE="/tmp/bot_output.log"
> "$LOG_FILE"

cd "$BOT_DIR"
eval "$START_CMD" </dev/tty 2>&1 | tee "$LOG_FILE" &
BOT_PID=$!
cd ..

CONNECTED=false
WAITING_SHOWN=false
TIMEOUT=300
ELAPSED=0

# Só conta como "conectado" quando há confirmação real de sucesso.
SUCCESS_PATTERN='(connection.{0,3}(is|:)?.{0,3}open|opened connection|logged in|client is ready|ready!|conectado com sucesso|sess(a|ã)o (restaurada|salva)|successfully connected|connection established|online)'

# Pedido de QR/código de pareamento NÃO é conexão — é só um aviso pra você agir.
WAITING_PATTERN='(qr code|escaneie|scan the|pairing code|c(o|ó)digo de pareamento|aguardando.*(qr|c(o|ó)digo))'

while [ $ELAPSED -lt $TIMEOUT ]; do
  if grep -qiE "$SUCCESS_PATTERN" "$LOG_FILE" 2>/dev/null; then
    echo ""
    echo "${G}[ ✅ ] Conexão detectada! Bot está respondendo.${X}"
    CONNECTED=true
    break
  fi

  if [ "$WAITING_SHOWN" = false ] && grep -qiE "$WAITING_PATTERN" "$LOG_FILE" 2>/dev/null; then
    echo ""
    echo "${Y}[ ⏸  ] Bot está pedindo QR/código. Escaneie ou digite o código agora — vou continuar aguardando.${X}"
    WAITING_SHOWN=true
  fi

  sleep 2
  ELAPSED=$((ELAPSED + 2))
  printf "\r${Y}⏳ Aguardando conexão... ${ELAPSED}s${X}   "
done

if [ "$CONNECTED" = false ]; then
  echo ""
  echo "${Y}[ AVISO ] Tempo esgotado. O bot pode precisar de interação manual (ex: escanear QR).${X}"
fi

# ── 7. Subir o uptime server e loop ──────────────────────────────────────────
echo ""
echo "${G}▶ Subindo servidor de uptime e mantendo bot online 24h...${X}"
sleep 1

kill $BOT_PID 2>/dev/null
bash run.sh
