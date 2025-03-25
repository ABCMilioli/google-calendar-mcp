
#!/bin/bash

# Download do script de instalação
curl -fsSL https://raw.githubusercontent.com/ABCMilioli/google-calendar-mcp/main/setup.sh -o setup.sh

# Dar permissão de execução
chmod +x setup.sh

# Executar o script
sudo ./setup.sh 
