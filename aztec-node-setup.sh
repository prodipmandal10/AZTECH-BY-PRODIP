#!/bin/bash

# Show blinking welcome banner
clear
echo -e "\e[5;36m"
echo "███████╗███████╗████████╗ ██████╗ ██████╗     ██████╗ ██╗   ██╗    ██████╗ ██████╗ ██╗   ██╗"
echo "╚══███╔╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗    ██╔══██╗██║   ██║    ██╔══██╗██╔══██╗╚██╗ ██╔╝"
echo "  ███╔╝ █████╗     ██║   ██║   ██║██████╔╝    ██████╔╝██║   ██║    ██████╔╝██████╔╝ ╚████╔╝ "
echo " ███╔╝  ██╔══╝     ██║   ██║   ██║██╔═══╝     ██╔═══╝ ██║   ██║    ██╔═══╝ ██╔═══╝   ╚██╔╝  "
echo "███████╗███████╗   ██║   ╚██████╔╝██║         ██║     ╚██████╔╝    ██║     ██║        ██║   "
echo "╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝         ╚═╝      ╚═════╝     ╚═╝     ╚═╝        ╚═╝   "
echo -e "\e[0m"
sleep 2

# Start automated setup
set -e

echo "========================================"
echo "🔧 Starting Full AZTEC Node Setup Script"
echo "========================================"

yes | bash <<'EOF'

echo "[1/10] Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

echo "[2/10] Installing Node.js v20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "[3/10] Installing essential packages..."
sudo apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf screen htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ufw apt-transport-https ca-certificates software-properties-common

echo "[4/10] Installing Docker and Docker Compose..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker --version
docker-compose --version

echo "[5/10] Installing AZTEC CLI..."
bash -i <(curl -s https://install.aztec.network)

echo "[6/10] Adding AZTEC CLI path to .bashrc..."
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "[7/10] Pulling latest AZTEC node docker image..."
aztec-up latest

echo "[8/10] Setting up firewall rules..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo ufw --force enable

EOF

echo "========================================"
echo "📝 Please enter AZTEC node configuration:"

read -p "Network (e.g. alpha-testnet): " network
network=${network:-alpha-testnet}

read -p "L1 RPC URLs (e.g. http://...): " l1_rpc
read -p "L1 Consensus Host URLs (e.g. http://...): " l1_consensus
read -p "Sequencer Validator Private Key (0x...): " priv_key
read -p "Sequencer Coinbase Address (0x...): " coinbase
read -p "P2P IP Address: " p2p_ip

cmd="aztec start --node --archiver --sequencer \
--network $network \
--l1-rpc-urls $l1_rpc \
--l1-consensus-host-urls $l1_consensus \
--sequencer.validatorPrivateKey $priv_key \
--sequencer.coinbase $coinbase \
--p2p.p2pIp $p2p_ip"

echo ""
echo "🚀 Starting AZTEC node in screen session 'AZ' with command:"
echo "$cmd"
echo ""

# Start screen session named AZ and run the command
screen -dmS AZ bash -c "$cmd; echo 'Type \"screen -r AZ\" to attach session, or \"Ctrl+A then D\" to detach.'; exec bash"

echo "✅ AZTEC node started in screen session 'AZ'."
echo "▶️ To attach session: screen -r AZ"
echo "🧹 To detach session: Press Ctrl+A then D"
