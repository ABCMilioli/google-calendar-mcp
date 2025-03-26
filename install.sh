#!/bin/bash

# Cores para output
verde="\e[32m"
vermelho="\e[31m"
amarelo="\e[33m"
azul="\e[34m"
reset="\e[0m"

echo -e "${azul}Iniciando instalação do ABC MCP Google Calendar...${reset}"
echo -e "${amarelo}Baixando script de configuração...${reset}"

# Baixar o script setup.sh
curl -fsSL https://raw.githubusercontent.com/ABCMilioli/google-calendar-mcp/main/setup.sh -o setup.sh

if [ $? -eq 0 ]; then
    echo -e "${verde}Script baixado com sucesso!${reset}"
    chmod +x setup.sh
    sudo ./setup.sh
else
    echo -e "${vermelho}Erro ao baixar o script. Verifique sua conexão com a internet e tente novamente.${reset}"
    exit 1
fi 
