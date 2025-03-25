# MCP Google Calendar Auto Installer

Script de instalação automatizada para o MCP Google Calendar Server.

## Requisitos

- Sistema operacional: Debian/Ubuntu
- Acesso root
- Credenciais do Google Calendar API (Client ID e Client Secret)

## Instalação

Para instalar, execute o seguinte comando:

```bash
curl -fsSL https://raw.githubusercontent.com/ABCMilioli/google-calendar-mcp/master/setup.sh | sudo bash
```

## Processo de Instalação

O script irá:

1. Verificar requisitos do sistema
2. Atualizar os pacotes do sistema
3. Instalar Node.js e dependências
4. Clonar o repositório do MCP Google Calendar
5. Instalar dependências do projeto
6. Configurar arquivos necessários
7. Solicitar credenciais do Google
8. Gerar refresh token
9. Compilar o projeto

## Configuração

Durante a instalação, você precisará fornecer:

1. GOOGLE_CLIENT_ID
2. GOOGLE_CLIENT_SECRET

Após fornecer as credenciais, o script irá:
1. Gerar uma URL de autorização
2. Aguardar o código de autorização
3. Gerar o refresh token
4. Configurar automaticamente o arquivo .env

## Uso

Após a instalação, o servidor MCP Google Calendar estará pronto para uso. As credenciais serão salvas no arquivo .env para referência futura.

## Suporte

Para suporte, abra uma issue no repositório: https://github.com/ABCMilioli/google-calendar-mcp/issues 