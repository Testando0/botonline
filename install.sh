#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

echo "${CYAN}
╔══════════════════════════════════════╗
║       🌸 SAKURA-BOT INSTALLER 🌸      ║
║         Instalando dependências...    ║
╚══════════════════════════════════════╝
${RESET}"

sleep 1

echo "${YELLOW}[ 1/5 ] Verificando Node.js...${RESET}"
if ! command -v node &> /dev/null; then
    echo "${RED}[ ERRO ] Node.js não encontrado! Instale o Node.js primeiro.${RESET}"
    exit 1
fi
echo "${GREEN}[ OK ] Node.js encontrado: $(node -v)${RESET}"
sleep 0.5

echo "${YELLOW}[ 2/5 ] Verificando yarn...${RESET}"
if ! command -v yarn &> /dev/null; then
    echo "${YELLOW}[ INFO ] Instalando yarn...${RESET}"
    npm install -g yarn
fi
echo "${GREEN}[ OK ] yarn encontrado: $(yarn -v)${RESET}"
sleep 0.5

echo "${YELLOW}[ 3/5 ] Entrando na pasta do bot...${RESET}"
if [ ! -d "sakura-botv6.9.5" ]; then
    echo "${RED}[ ERRO ] Pasta sakura-botv6.9.5 não encontrada!${RESET}"
    exit 1
fi
cd sakura-botv6.9.5
echo "${GREEN}[ OK ] Pasta encontrada!${RESET}"
sleep 0.5

echo "${YELLOW}[ 4/5 ] Instalando pacotes do bot...${RESET}"
yarn install
if [ $? -ne 0 ]; then
    echo "${RED}[ ERRO ] Falha ao instalar pacotes! Tentando com npm...${RESET}"
    npm install
fi
echo "${GREEN}[ OK ] Pacotes instalados com sucesso!${RESET}"
sleep 0.5

echo "${YELLOW}[ 5/5 ] Finalizando instalação...${RESET}"
cd ..
sleep 1

echo "${GREEN}
╔══════════════════════════════════════╗
║   ✅ INSTALAÇÃO CONCLUÍDA COM ÊXITO! ║
║                                      ║
║   Para iniciar o bot, execute:       ║
║   ${WHITE}bash start.sh${GREEN}                      ║
╚══════════════════════════════════════╝
${RESET}"
