#!/bin/bash

# Banner
echo -e "
    █████╗ ██████╗  ██████╗    ███╗   ███╗ ██████╗██████╗     ██████╗     ███████╗ █████╗ ██╗     ███████╗███╗   ██╗██████╗ ██████╗ ███████╗██████╗ 
   ██╔══██╗██╔══██╗██╔════╝    ████╗ ████║██╔════╝██╔══██╗    ██          ██╔══██╗██╔══██╗██║     ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗
   ███████║██████╔╝██║         ██╔████╔██║██║     ██████╔╝    ██  ███     ██      ███████║██║     █████╗  ██╔██╗ ██║██║  ██║██████╔╝█████╗  ██████╔╝
   ██╔══██║██╔══██╗██║         ██║╚██╔╝██║██║     ██╔         ██╔══██╗    ██╔══██╗██╔══██║██║     ██╔══╝  ██║╚██╗██║██║  ██║██╔══██╗██╔══╝  ██╔══██╗
   ██║  ██║██████╔╝╚██████╗    ██║ ╚═╝ ██║╚██████╗██║         ██████╔╝    ██║████║██║  ██║███████╗███████╗██║ ╚████║██████╔╝██║  ██║███████╗██║  ██║
   ╚═╝  ╚═╝╚═════╝  ╚═════╝    ╚═╝     ╚═╝ ╚═════╝╚═╝         ╚═════╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                             
              Auto Instalador do ABC MCP G-CALENDAR
"

# Cores
verde="\e[32m"
vermelho="\e[31m"
amarelo="\e[33m"
azul="\e[34m"
roxo="\e[35m"
reset="\e[0m"

## Função para verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${vermelho}Este script precisa ser executado como root${reset}"
        exit
    fi
}

## Função para detectar o sistema operacional
detect_os() {
    if [ -f /etc/debian_version ]; then
        echo -e "${azul}Sistema Debian/Ubuntu detectado${reset}"
        OS="debian"
    else
        echo -e "${vermelho}Sistema operacional não suportado${reset}"
        exit 1
    fi
}

## Função para coletar informações do Google Calendar
get_google_credentials() {
    exec < /dev/tty
    
    # GOOGLE_CLIENT_ID
    echo -e "${azul}Configuração do Google Calendar${reset}"
    echo ""
    echo -e "\e[97mPasso${amarelo} 1/2${reset}"
    echo -e "${amarelo}Digite o GOOGLE_CLIENT_ID${reset}"
    echo -e "${vermelho}Para cancelar a instalação digite: exit${reset}"
    echo ""
    read -p "> " GOOGLE_CLIENT_ID
    if [ "$GOOGLE_CLIENT_ID" = "exit" ]; then
        echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
        exit 1
    fi
    
    # GOOGLE_CLIENT_SECRET
    echo -e "${azul}Configuração do Google Calendar${reset}"
    echo ""
    echo -e "\e[97mPasso${amarelo} 2/2${reset}"
    echo -e "${amarelo}Digite o GOOGLE_CLIENT_SECRET${reset}"
    echo -e "${vermelho}Para cancelar a instalação digite: exit${reset}"
    echo ""
    read -p "> " GOOGLE_CLIENT_SECRET
    if [ "$GOOGLE_CLIENT_SECRET" = "exit" ]; then
        echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
        exit 1
    fi
    
    # Confirmação
    echo -e "${azul}Confirme as informações:${reset}"
    echo ""
    echo -e "${amarelo}GOOGLE_CLIENT_ID:${reset} $GOOGLE_CLIENT_ID"
    echo -e "${amarelo}GOOGLE_CLIENT_SECRET:${reset} $GOOGLE_CLIENT_SECRET"
    echo ""
    echo -e "${vermelho}Para cancelar a instalação digite: exit${reset}"
    echo ""
    read -p "As informações estão corretas? (Y/N/exit): " confirmacao
    
    case $confirmacao in
        [Yy]* )
            exec <&-  # Fecha o /dev/tty
            return 0
            ;;
        [Nn]* )
            echo -e "${amarelo}Reiniciando coleta de informações...${reset}"
            sleep 2
            exec <&-  # Fecha o /dev/tty antes de reiniciar
            get_google_credentials
            ;;
        "exit" )
            echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
            exit 1
            ;;
        * )
            echo -e "${vermelho}Opção inválida${reset}"
            echo -e "${amarelo}Pressione ENTER para continuar...${reset}"
            read -p "> " resposta
            if [ "$resposta" = "exit" ]; then
                echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
                exit 1
            fi
            exec <&-  # Fecha o /dev/tty antes de reiniciar
            get_google_credentials
            ;;
    esac
}

## Função para instalar dependências
install_dependencies() {
    # Passo 0 - Identificar o OS
    if [ -f /etc/debian_version ]; then
        echo -e "${azul}Sistema Debian/Ubuntu detectado${reset}"
        OS="debian"
    else
        echo -e "${vermelho}Sistema operacional não suportado${reset}"
        exit 1
    fi

    # Passo 1 - Atualizar pacotes
    echo -e "${azul}Passo 1 - Atualizando pacotes...${reset}"
    sudo apt update

    # Passo 2 - Acessar diretório /opt
    echo -e "${azul}Passo 2 - Acessando diretório /opt...${reset}"
    cd /opt

    # Passo 3 - Clonar repositório
    echo -e "${azul}Passo 3 - Clonando repositório...${reset}"
    if [ ! -d "/opt/google-calendar" ]; then
        git clone https://github.com/v-3/google-calendar.git
    else
        echo -e "${amarelo}Diretório já existe, atualizando...${reset}"
        cd google-calendar
        git pull
        cd ..
    fi

    # Passo 4 - Acessar diretório do projeto
    echo -e "${azul}Passo 4 - Acessando diretório do projeto...${reset}"
    cd google-calendar

    # Configurar permissões do diretório
    echo -e "${azul}Configurando permissões do diretório...${reset}"
    sudo chown -R 1000:1000 /opt/google-calendar
    sudo chmod -R 755 /opt/google-calendar

    # Criar volume Docker para o MCP Calendar
    echo -e "${azul}Criando volume Docker para o MCP Calendar...${reset}"
    if docker volume ls | grep -q "google-calendar-mcp"; then
        docker volume rm google-calendar-mcp
    fi
    docker volume create google-calendar-mcp
    
    # Ajustar permissões do diretório
    echo -e "${azul}Ajustando permissões do diretório...${reset}"
    sudo chown -R 1000:1000 /opt/google-calendar

    # Passo 5 - Configurar Node.js
    echo -e "${azul}Passo 5 - Configurando Node.js...${reset}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

    # Passo 6 - Instalar Node.js
    echo -e "${azul}Passo 6 - Instalando Node.js...${reset}"
    sudo apt install -y nodejs

    # Passo 7 - Instalar TypeScript globalmente
    echo -e "${azul}Passo 7 - Instalando TypeScript...${reset}"
    sudo npm install -g typescript

    # Passo 8 - Instalar npm
    echo -e "${azul}Passo 8 - Instalando npm...${reset}"
    apt install npm

    # Passo 9 - Instalar dependências do MCP
    echo -e "${azul}Passo 9 - Instalando dependências do MCP...${reset}"
    npm install @modelcontextprotocol/sdk googleapis google-auth-library zod

    # Passo 10 - Instalar dependências de desenvolvimento
    echo -e "${azul}Passo 10 - Instalando dependências de desenvolvimento...${reset}"
    npm install -D @types/node typescript

    # Instalar dotenv (necessário para o .env)
    echo -e "${azul}Instalando dotenv...${reset}"
    npm install dotenv

    # Passo 11 - Compilar o projeto
    echo -e "${azul}Passo 11 - Compilando o projeto...${reset}"
    npm run build

    # Passo 12 - Acessar diretório build
    echo -e "${azul}Passo 12 - Acessando diretório build...${reset}"
    cd build/
}

## Função para configurar arquivo .env
setup_env() {
    echo -e "${azul}Criando arquivo .env...${reset}"
    cat > .env << EOF
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
GOOGLE_REDIRECT_URI=urn:ietf:wg:oauth:2.0:oob
GOOGLE_REFRESH_TOKEN=
EOF
}

## Função para criar arquivo getRefreshToken.js
create_refresh_token_script() {
    echo -e "${azul}Criando script getRefreshToken.js...${reset}"
    cat > getRefreshToken.js << 'EOF'
// getRefreshToken.js
import readline from 'readline';
import { google } from 'googleapis';
import dotenv from 'dotenv';

dotenv.config();

const { GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET } = process.env;

if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
  console.error('Variáveis de ambiente GOOGLE_CLIENT_ID ou GOOGLE_CLIENT_SECRET não definidas.');
  process.exit(1);
}

const REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob';
const SCOPES = [
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events'
];

const oauth2Client = new google.auth.OAuth2(
  GOOGLE_CLIENT_ID,
  GOOGLE_CLIENT_SECRET,
  REDIRECT_URI
);

// Se um código de autorização foi fornecido como argumento
if (process.argv[2]) {
  const code = process.argv[2];
  oauth2Client.getToken(code).then(({ tokens }) => {
    if (tokens.refresh_token) {
      console.log(tokens.refresh_token);
      process.exit(0);
    } else {
      console.error('Nenhum refresh_token foi retornado.');
      process.exit(1);
    }
  }).catch(error => {
    console.error('Erro ao trocar o código por tokens:', error);
    process.exit(1);
  });
} else {
  // Modo interativo - gerar URL de autorização
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: SCOPES
  });

  console.clear();
  console.log('Abra a seguinte URL no navegador e siga o processo de autorização:\n');
  console.log(authUrl);
  console.log('\nApós autorizar, cole o código no prompt do instalador.\n');
}
EOF
}

## Função para obter refresh token
get_refresh_token() {
    exec < /dev/tty
    
    echo -e "${azul}Configuração do Código de Autorização${reset}"
    echo ""
    echo -e "${amarelo}Digite o código de autorização obtido do Google${reset}"
    echo -e "${vermelho}Para cancelar a instalação digite: exit${reset}"
    echo ""
    read -p "> " AUTH_CODE
    
    if [ "$AUTH_CODE" = "exit" ]; then
        echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
        exit 1
    fi
    
    if [ -z "$AUTH_CODE" ]; then
        echo -e "${vermelho}Código de autorização não pode estar vazio${reset}"
        echo -e "${amarelo}Tente novamente...${reset}"
        sleep 2
        get_refresh_token
        return
    fi
    
    # Executar script para obter o refresh token
    echo -e "${azul}Processando código de autorização...${reset}"
    REFRESH_TOKEN=$(node getRefreshToken.js "$AUTH_CODE")
    
    if [ -z "$REFRESH_TOKEN" ]; then
        echo -e "${vermelho}Não foi possível obter o refresh token${reset}"
        echo -e "${amarelo}Tente novamente...${reset}"
        sleep 2
        get_refresh_token
        return
    fi
    
    # Confirmação
    echo -e "${azul}Confirme as informações:${reset}"
    echo ""
    echo -e "${amarelo}REFRESH_TOKEN:${reset} $REFRESH_TOKEN"
    echo ""
    echo -e "${vermelho}Para cancelar a instalação digite: exit${reset}"
    echo ""
    read -p "As informações estão corretas? (Y/N/exit): " confirmacao
    
    case $confirmacao in
        [Yy]* )
            # Atualizar o arquivo .env com o refresh token
            sed -i "s|GOOGLE_REFRESH_TOKEN=.*|GOOGLE_REFRESH_TOKEN=$REFRESH_TOKEN|" .env
            echo -e "${verde}Refresh token salvo com sucesso!${reset}"
            exec <&-  # Fecha o /dev/tty
            return 0
            ;;
        [Nn]* )
            echo -e "${amarelo}Reiniciando coleta de informações...${reset}"
            sleep 2
            exec <&-  # Fecha o /dev/tty antes de reiniciar
            get_refresh_token
            ;;
        "exit" )
            echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
            exit 1
            ;;
        * )
            echo -e "${vermelho}Opção inválida${reset}"
            echo -e "${amarelo}Pressione ENTER para continuar...${reset}"
            read -p "> " resposta
            if [ "$resposta" = "exit" ]; then
                echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
                exit 1
            fi
            exec <&-  # Fecha o /dev/tty antes de reiniciar
            get_refresh_token
            ;;
    esac
}

## Função para criar o arquivo index.js
create_index_js() {
    echo -e "${azul}Criando arquivo index.js...${reset}"
    cat > index.js << 'EOF'
import { MCPServer } from "@modelcontextprotocol/sdk";
import { google } from "googleapis";
import { OAuth2Client } from "google-auth-library";
import { z } from "zod";
import dotenv from "dotenv";

dotenv.config();

const {
  GOOGLE_CLIENT_ID,
  GOOGLE_CLIENT_SECRET,
  GOOGLE_REFRESH_TOKEN,
} = process.env;

if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET || !GOOGLE_REFRESH_TOKEN) {
  console.error("Missing required environment variables");
  process.exit(1);
}

const oauth2Client = new OAuth2Client(
  GOOGLE_CLIENT_ID,
  GOOGLE_CLIENT_SECRET,
  "urn:ietf:wg:oauth:2.0:oob"
);

oauth2Client.setCredentials({
  refresh_token: GOOGLE_REFRESH_TOKEN,
});

const calendar = google.calendar({ version: "v3", auth: oauth2Client });

// Definição dos schemas
const eventSchema = z.object({
  summary: z.string(),
  description: z.string().optional(),
  start: z.object({
    dateTime: z.string(),
    timeZone: z.string(),
  }),
  end: z.object({
    dateTime: z.string(),
    timeZone: z.string(),
  }),
});

const toolDefinitions = [
  {
    name: "create_event",
    description: "Create a new event in Google Calendar",
    parameters: eventSchema,
  },
  {
    name: "list_events",
    description: "List events from Google Calendar",
    parameters: z.object({
      maxResults: z.number().optional(),
      timeMin: z.string().optional(),
      timeMax: z.string().optional(),
    }),
  },
];

// Inicialização do servidor MCP
const server = new MCPServer({
  tools: toolDefinitions,
  async executeOperation({ name, parameters }) {
    try {
      switch (name) {
        case "create_event":
          const event = await calendar.events.insert({
            calendarId: "primary",
            requestBody: parameters,
          });
          return event.data;

        case "list_events":
          const events = await calendar.events.list({
            calendarId: "primary",
            ...parameters,
          });
          return events.data.items;

        default:
          throw new Error(`Unknown operation: ${name}`);
      }
    } catch (error) {
      console.error("Error executing operation:", error);
      throw error;
    }
  },
});

// Tratamento de erros e keep-alive
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Iniciar o servidor com retry em caso de falha
async function startServer() {
  try {
    await server.listen(3000);
    console.log("MCP server is running on port 3000");
  } catch (error) {
    console.error("Failed to start server:", error);
    console.log("Retrying in 5 seconds...");
    setTimeout(startServer, 5000);
  }
}

startServer();
EOF

    echo -e "${verde}Arquivo index.js criado com sucesso!${reset}"
}

## Função principal
main() {
    check_root
    detect_os
    get_google_credentials
    install_dependencies
    setup_env
    create_refresh_token_script
    
    echo -e "${azul}Executando script de obtenção do refresh token...${reset}"
    echo -e "${amarelo}Abra a URL fornecida no navegador e siga o processo de autorização${reset}"
    node getRefreshToken.js
    
    get_refresh_token
    create_index_js

    echo -e "${verde}Instalação concluída com sucesso!${reset}"
    echo -e "${azul}Informações do arquivo .env:${reset}"
    cat .env
}

# Executa a função principal
main 
