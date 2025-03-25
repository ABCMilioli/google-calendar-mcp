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
    while true; do
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
                return 0
                ;;
            [Nn]* )
                echo -e "${amarelo}Reiniciando coleta de informações...${reset}"
                sleep 2
                continue
                ;;
            "exit" )
                echo -e "${vermelho}Instalação cancelada pelo usuário${reset}"
                exit 1
                ;;
            * )
                echo -e "${vermelho}Opção inválida${reset}"
                echo -e "${amarelo}Pressione ENTER para continuar...${reset}"
                read
                continue
                ;;
        esac
    done
}

## Função para instalar dependências
install_dependencies() {
    echo -e "${azul}Atualizando pacotes...${reset}"
    apt update

    echo -e "${azul}Acessando diretório /opt...${reset}"
    cd /opt

    echo -e "${azul}Clonando repositório...${reset}"
    git clone https://github.com/v-3/google-calendar.git

    echo -e "${azul}Acessando diretório do projeto...${reset}"
    cd google-calendar

    echo -e "${azul}Configurando Node.js...${reset}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    apt install -y nodejs

    echo -e "${azul}Instalando TypeScript...${reset}"
    npm install -g typescript
    apt install npm

    echo -e "${azul}Instalando dependências do projeto...${reset}"
    npm install @modelcontextprotocol/sdk googleapis google-auth-library zod
    npm install -D @types/node typescript
    npm install dotenv

    echo -e "${azul}Compilando o projeto...${reset}"
    npm run build

    echo -e "${azul}Acessando diretório build...${reset}"
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

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  prompt: 'consent',
  scope: SCOPES
});

console.clear();
console.log('Abra a seguinte URL no navegador e siga o processo de autorização:\n');
console.log(authUrl);
console.log('\nApós autorizar, cole o código abaixo:\n');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('Código de autorização: ', async (code) => {
  try {
    rl.close();
    const { tokens } = await oauth2Client.getToken(code);
    console.log('\nTokens obtidos com sucesso!\n');

    if (tokens.refresh_token) {
      console.log('Seu novo REFRESH TOKEN é:\n');
      console.log(tokens.refresh_token);
      console.log('\nSalve este token no seu .env como GOOGLE_REFRESH_TOKEN.');
    } else {
      console.warn('Nenhum refresh_token foi retornado. Use prompt: "consent" e access_type: "offline".');
    }
  } catch (error) {
    console.error('Erro ao trocar o código por tokens:\n', error.response?.data || error.message || error);
  }
});
EOF
}

## Função para obter refresh token
get_refresh_token() {
    echo -e "${azul}Executando script de obtenção do refresh token...${reset}"
    node getRefreshToken.js

    echo -e "${amarelo}Digite o refresh token obtido:${reset}"
    read -p "> " REFRESH_TOKEN

    # Atualizar o arquivo .env com o refresh token
    sed -i "s/GOOGLE_REFRESH_TOKEN=.*/GOOGLE_REFRESH_TOKEN=$REFRESH_TOKEN/" .env
}

## Função para criar arquivo index.js
create_index_js() {
    echo -e "${azul}Criando arquivo index.js...${reset}"
    cat > index.js << 'EOF'
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema, } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { google } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Google Calendar client
console.error(`Iniciando Oauth2Cliente...`);
console.error('São essas as variaveis definidas...');
console.error('GOOGLE_CLIENT_ID:', process.env.GOOGLE_CLIENT_ID || '[NÃO DEFINIDA]');
console.error('GOOGLE_CLIENT_SECRET:', process.env.GOOGLE_CLIENT_SECRET || '[NÃO DEFINIDA]');
console.error('GOOGLE_REDIRECT_URI:', process.env.GOOGLE_REDIRECT_URI || '[NÃO DEFINIDA]');
console.error('GOOGLE_REFRESH_TOKEN:', process.env.GOOGLE_REFRESH_TOKEN || '[NÃO DEFINIDA]');

const oauth2Client = new OAuth2Client({
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    redirectUri: process.env.GOOGLE_REDIRECT_URI,
});
// Set credentials from environment variables
oauth2Client.setCredentials({
    refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
});
const calendar = google.calendar({ version: 'v3', auth: oauth2Client });
// Validation schemas
const schemas = {
    toolInputs: {
        listEvents: z.object({
            timeMin: z.string().optional(),
            timeMax: z.string().optional(),
            maxResults: z.number().optional(),
        }),
        createEvent: z.object({
            summary: z.string(),
            description: z.string().optional(),
            startTime: z.string(),
            endTime: z.string(),
            attendees: z.array(z.string()).optional(),
        }),
        updateEvent: z.object({
            eventId: z.string(),
            summary: z.string().optional(),
            description: z.string().optional(),
            startTime: z.string().optional(),
            endTime: z.string().optional(),
        }),
        deleteEvent: z.object({
            eventId: z.string(),
        }),
        findFreeTime: z.object({
            timeMin: z.string(),
            timeMax: z.string(),
            duration: z.number(), // duration in minutes
        })
    }
};
// Tool definitions
const TOOL_DEFINITIONS = [
    {
        name: "list_events",
        description: "List calendar events within a specified time range",
        inputSchema: {
            type: "object",
            properties: {
                timeMin: {
                    type: "string",
                    description: "Start time (ISO string)",
                },
                timeMax: {
                    type: "string",
                    description: "End time (ISO string)",
                },
                maxResults: {
                    type: "number",
                    description: "Maximum number of events to return",
                },
            },
        },
    },
    {
        name: "create_event",
        description: "Create a new calendar event",
        inputSchema: {
            type: "object",
            properties: {
                summary: {
                    type: "string",
                    description: "Event title",
                },
                description: {
                    type: "string",
                    description: "Event description",
                },
                startTime: {
                    type: "string",
                    description: "Event start time (ISO string)",
                },
                endTime: {
                    type: "string",
                    description: "Event end time (ISO string)",
                },
                attendees: {
                    type: "array",
                    items: {
                        type: "string",
                    },
                    description: "List of attendee email addresses",
                },
            },
            required: ["summary", "startTime", "endTime"],
        },
    },
    {
        name: "update_event",
        description: "Update an existing calendar event",
        inputSchema: {
            type: "object",
            properties: {
                eventId: {
                    type: "string",
                    description: "ID of the event to update",
                },
                summary: {
                    type: "string",
                    description: "New event title",
                },
                description: {
                    type: "string",
                    description: "New event description",
                },
                startTime: {
                    type: "string",
                    description: "New start time (ISO string)",
                },
                endTime: {
                    type: "string",
                    description: "New end time (ISO string)",
                },
            },
            required: ["eventId"],
        },
    },
    {
        name: "delete_event",
        description: "Delete a calendar event",
        inputSchema: {
            type: "object",
            properties: {
                eventId: {
                    type: "string",
                    description: "ID of the event to delete",
                },
            },
            required: ["eventId"],
        },
    },
    {
        name: "find_free_time",
        description: "Find available time slots in the calendar",
        inputSchema: {
            type: "object",
            properties: {
                timeMin: {
                    type: "string",
                    description: "Start of time range (ISO string)",
                },
                timeMax: {
                    type: "string",
                    description: "End of time range (ISO string)",
                },
                duration: {
                    type: "number",
                    description: "Desired duration in minutes",
                },
            },
            required: ["timeMin", "timeMax", "duration"],
        },
    },
];
// Tool implementation handlers
const toolHandlers = {
    async list_events(args) {
        const { timeMin, timeMax, maxResults = 10 } = schemas.toolInputs.listEvents.parse(args);
        const response = await calendar.events.list({
            calendarId: 'primary',
            timeMin: timeMin || new Date().toISOString(),
            timeMax,
            maxResults,
            singleEvents: true,
            orderBy: 'startTime',
        });
        const events = response.data.items || [];
        const formattedEvents = events.map(event => {
            return `• ${event.summary}\n  Start: ${event.start?.dateTime || event.start?.date}\n  End: ${event.end?.dateTime || event.end?.date}\n  ID: ${event.id}`;
        }).join('\n\n');
        return {
            content: [{
                    type: "text",
                    text: events.length ?
                        `Found ${events.length} events:\n\n${formattedEvents}` :
                        "No events found in the specified time range."
                }]
        };
    },
    async create_event(args) {
        const { summary, description, startTime, endTime, attendees } = schemas.toolInputs.createEvent.parse(args);
        const event = await calendar.events.insert({
            calendarId: 'primary',
            requestBody: {
                summary,
                description,
                start: {
                    dateTime: startTime,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                end: {
                    dateTime: endTime,
                    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                },
                attendees: attendees?.map(email => ({ email })),
            },
        });
        return {
            content: [{
                    type: "text",
                    text: `Event created successfully!\nID: ${event.data.id}\nLink: ${event.data.htmlLink}`
                }]
        };
    },
    async update_event(args) {
        const { eventId, summary, description, startTime, endTime } = schemas.toolInputs.updateEvent.parse(args);
        // Get existing event
        const existingEvent = await calendar.events.get({
            calendarId: 'primary',
            eventId,
        });
        // Prepare update payload
        const updatePayload = {
            summary: summary || existingEvent.data.summary,
            description: description || existingEvent.data.description,
        };
        if (startTime) {
            updatePayload.start = {
                dateTime: startTime,
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            };
        }
        if (endTime) {
            updatePayload.end = {
                dateTime: endTime,
                timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            };
        }
        await calendar.events.update({
            calendarId: 'primary',
            eventId,
            requestBody: updatePayload,
        });
        return {
            content: [{
                    type: "text",
                    text: `Event ${eventId} updated successfully!`
                }]
        };
    },
    async delete_event(args) {
        const { eventId } = schemas.toolInputs.deleteEvent.parse(args);
        await calendar.events.delete({
            calendarId: 'primary',
            eventId,
        });
        return {
            content: [{
                    type: "text",
                    text: `Event ${eventId} deleted successfully!`
                }]
        };
    },
    async find_free_time(args) {
        const { timeMin, timeMax, duration } = schemas.toolInputs.findFreeTime.parse(args);
        // Get existing events in the time range
        const response = await calendar.events.list({
            calendarId: 'primary',
            timeMin,
            timeMax,
            singleEvents: true,
            orderBy: 'startTime',
        });
        const events = response.data.items || [];
        const freeTimes = [];
        let currentTime = new Date(timeMin);
        const endTime = new Date(timeMax);
        const durationMs = duration * 60000; // Convert minutes to milliseconds
        // Find free time slots
        for (const event of events) {
            const eventStart = new Date(event.start?.dateTime || event.start?.date || '');
            // Check if there's enough time before the event
            if (eventStart.getTime() - currentTime.getTime() >= durationMs) {
                freeTimes.push({
                    start: currentTime.toISOString(),
                    end: new Date(eventStart.getTime() - 1).toISOString(),
                });
            }
            currentTime = new Date(event.end?.dateTime || event.end?.date || '');
        }
        // Check for free time after the last event
        if (endTime.getTime() - currentTime.getTime() >= durationMs) {
            freeTimes.push({
                start: currentTime.toISOString(),
                end: endTime.toISOString(),
            });
        }
        const formattedTimes = freeTimes.map(slot => `• ${new Date(slot.start).toLocaleString()} - ${new Date(slot.end).toLocaleString()}`).join('\n');
        return {
            content: [{
                    type: "text",
                    text: freeTimes.length ?
                        `Encontrado ${freeTimes.length} nesse periodo:\n\n${formattedTimes}` :
                        `Nao encontrou tempo disponivel ${duration}.`
                }]
        };
    },
};
// Initialize MCP server
const server = new Server({
    name: "google-calendar-server",
    version: "1.0.0",
}, {
    capabilities: {
        tools: {},
    },
});
// Register tool handlers
server.setRequestHandler(ListToolsRequestSchema, async () => {
    console.error("Tools requested by client");
    return { tools: TOOL_DEFINITIONS };
});
server.setRequestHandler(ListToolsRequestSchema, async () => {
    console.error("Tools requested by client");
    console.error("Returning tools:", JSON.stringify(TOOL_DEFINITIONS, null, 2));
    return { tools: TOOL_DEFINITIONS };
});
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
        const handler = toolHandlers[name];
        if (!handler) {
            throw new Error(`Unknown tool: ${name}`);
        }
        return await handler(args);
    }
    catch (error) {
        console.error(`Error executing tool ${name}:`, error);
        throw error;
    }
});
// Start the server
async function main() {
    try {
        // Check for required environment variables
        const requiredEnvVars = [
            'GOOGLE_CLIENT_ID',
            'GOOGLE_CLIENT_SECRET',
            'GOOGLE_REDIRECT_URI',
            'GOOGLE_REFRESH_TOKEN'
        ];
        const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
        if (missingVars.length > 0) {
            console.error(`Missing required environment variables: ${missingVars.join(', ')}`);
            process.exit(1);
        }
        console.error("Starting server with env vars:", {
            clientId: process.env.GOOGLE_CLIENT_ID?.substring(0, 5) + '...',
            clientSecret: process.env.GOOGLE_CLIENT_SECRET?.substring(0, 5) + '...',
            redirectUri: process.env.GOOGLE_REDIRECT_URI,
            hasRefreshToken: !!process.env.GOOGLE_REFRESH_TOKEN
        });
        const transport = new StdioServerTransport();
        console.error("Created transport");
        await server.connect(transport);
        console.error("Connected to transport");
        console.error("Google Calendar MCP Server running on stdio");
    }
    catch (error) {
        console.error("Startup error:", error);
        process.exit(1);
    }
}
const args = process.argv.slice(2);

if (args.length > 0) {
  // Execução direta via CLI com função e argumentos
  const funcao = args[0];
  const input = args[1] ? JSON.parse(args[1]) : {};

  if (toolHandlers[funcao]) {
    toolHandlers[funcao](input)
      .then((res) => {
        console.log(JSON.stringify(res, null, 2));
        process.exit(0);
      })
      .catch((err) => {
        console.error(`Erro ao executar ${funcao}:`, err);
        process.exit(1);
      });
  } else {
    console.error(`❌ Função desconhecida: ${funcao}`);
    process.exit(1);
  }
} else {
  // Modo MCP servidor via stdio
  main().catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
  });
}
EOF
}

## Função principal
main() {
    check_root
    detect_os
    get_google_credentials
    install_dependencies
    setup_env
    create_refresh_token_script
    get_refresh_token
    create_index_js

    echo -e "${verde}Instalação concluída com sucesso!${reset}"
    echo -e "${azul}Informações do arquivo .env:${reset}"
    cat .env
}

# Executa a função principal
main 
