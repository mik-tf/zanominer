#!/bin/bash

# Comprehensive Zano Wallet, Miner, and Staking Setup Script with Systemd
# For Ubuntu Desktop
# Supports full installation: dependencies, wallet creation, mining, and staking as system services

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables
ZANO_VERSION="1.5.0.143"
TT_MINER_VERSION="2023.1.0"
STRATUM_PORT="11555"
POS_RPC_PORT="50005"

# Logging functions
log() {
    echo -e "${GREEN}[ZANO SETUP]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Dependency check and installation
install_dependencies() {
    log "Checking and installing system dependencies..."
    
    # Update package lists
    sudo apt update

    # Install essential dependencies
    sudo apt install -y \
        wget \
        curl \
        tar \
        build-essential \
        software-properties-common \
        git \
        nvidia-cuda-toolkit \
        nvidia-driver-535 \
        gpg

    # Optional: Install password generator
    if ! command -v pwgen &> /dev/null; then
        sudo apt install -y pwgen
    fi
}

# Download Zano components
download_zano_components() {
    log "Downloading Zano components..."
    
    # Create Zano directory
    mkdir -p ~/zano-project
    cd ~/zano-project

    # Download Zano CLI Wallet
    wget https://github.com/zano-project/zano/releases/download/v${ZANO_VERSION}/zano-linux-x64-v${ZANO_VERSION}.tar.bz2
    
    # Verify download
    if [ ! -f zano-linux-x64-v${ZANO_VERSION}.tar.bz2 ]; then
        error "Failed to download Zano CLI Wallet"
    fi

    # Extract
    tar -xvjf zano-linux-x64-v${ZANO_VERSION}.tar.bz2
}

# Generate wallet with interactive prompts
create_zano_wallet() {
    log "Creating Zano Wallet..."

    # Prompt for wallet name
    read -p "Enter a name for your wallet (e.g., myzanowallet): " WALLET_NAME
    
    # Generate secure passwords
    WALLET_PASSWORD=$(pwgen -s 16 1)
    SEED_PASSWORD=$(pwgen -s 16 1)

    log "Generating wallet: ${WALLET_NAME}.wallet"
    
    # Navigate to Zano directory
    cd ~/zano-project/zano-linux-x64-v${ZANO_VERSION}

    # Start daemon in background
    log "Starting Zano daemon to sync blockchain..."
    ./zanod &
    ZANOD_PID=$!

    # Wait for daemon to start
    sleep 30

    # Create wallet (non-interactive)
    ./simplewallet --generate-new-wallet=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
${WALLET_PASSWORD}
EOF

    # Open wallet to show address
    WALLET_ADDRESS=$(./simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
address
exit
EOF
)

    # Extract wallet address (assuming last line is the address)
    WALLET_ADDRESS=$(echo "$WALLET_ADDRESS" | grep -oP 'Zx[a-zA-Z0-9]+')

    log "Wallet created successfully!"
    echo -e "${BLUE}Wallet Address: ${WALLET_ADDRESS}${NC}"

    # Save seed phrase
    SEED_PHRASE=$(./simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
show_seed
${SEED_PASSWORD}
${SEED_PASSWORD}
exit
EOF
)

    # Kill daemon
    kill $ZANOD_PID

    # Save wallet details securely
    mkdir -p ~/zano-wallet-backup
    echo "Wallet Name: ${WALLET_NAME}" > ~/zano-wallet-backup/wallet-details.txt
    echo "Wallet Address: ${WALLET_ADDRESS}" >> ~/zano-wallet-backup/wallet-details.txt
    echo "Wallet Password: ${WALLET_PASSWORD}" >> ~/zano-wallet-backup/wallet-details.txt
    echo "Seed Password: ${SEED_PASSWORD}" >> ~/zano-wallet-backup/wallet-details.txt
    echo "Seed Phrase: ${SEED_PHRASE}" >> ~/zano-wallet-backup/wallet-details.txt

    chmod 600 ~/zano-wallet-backup/wallet-details.txt
}

# Setup TT-Miner
setup_tt_miner() {
    log "Setting up TT-Miner..."
    
    cd ~/zano-project

    # Download TT-Miner
    wget https://github.com/TrailingStop/TT-Miner-release/releases/download/${TT_MINER_VERSION}/TT-Miner-${TT_MINER_VERSION}.tar.gz
    tar -xf TT-Miner-${TT_MINER_VERSION}.tar.gz
    chmod +x TT-Miner
}

# Create systemd service files
create_systemd_services() {
    log "Creating systemd service files..."

    # Ask about separate reward address for staking rewards
    read -p "Do you want to use a separate address for mining rewards? (y/n): " USE_SEPARATE_REWARD

    # Determine reward address
    if [[ $USE_SEPARATE_REWARD =~ ^[Yy]$ ]]; then
        read -p "Enter the separate reward address: " REWARD_ADDRESS
        REWARD_OPTION="--pos-mining-reward-address=${REWARD_ADDRESS}"
    else
        REWARD_OPTION=""
    fi

    # Zano Daemon Systemd Service
    sudo tee /etc/systemd/system/zanod.service > /dev/null << EOF
[Unit]
Description=Zano Blockchain Daemon
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=~/zano-project/zano-linux-x64-v${ZANO_VERSION}
ExecStart=~/zano-project/zano-linux-x64-v${ZANO_VERSION}/zanod --stratum --stratum-miner-address=${WALLET_ADDRESS} --stratum-bind-port=${STRATUM_PORT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # TT-Miner Systemd Service
    sudo tee /etc/systemd/system/tt-miner.service > /dev/null << EOF
[Unit]
Description=TT-Miner for Zano
After=zanod.service
Requires=zanod.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=~/zano-project
ExecStart=~/zano-project/TT-Miner -luck -coin ZANO -u zano-miner -o 127.0.0.1:${STRATUM_PORT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # PoS Mining Systemd Service
    sudo tee /etc/systemd/system/zano-pos-mining.service > /dev/null << EOF
[Unit]
Description=Zano Proof of Stake Mining
After=zanod.service
Requires=zanod.service

[Service]
Type=simple
User=${USER}
WorkingDirectory=~/zano-project/zano-linux-x64-v${ZANO_VERSION}
ExecStart=~/zano-project/zano-linux-x64-v${ZANO_VERSION}/simplewallet \
    --wallet-file=${WALLET_NAME}.wallet \
    --rpc-bind-port=${POS_RPC_PORT} \
    --do-pos-mining \
    --log-level=0 \
    --log-file=~/zano-project/pos-mining.log \
    --deaf \
    ${REWARD_OPTION}
ExecStartPost=/bin/bash -c 'echo "${WALLET_PASSWORD}" | sudo tee /etc/zano-wallet-password > /dev/null'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Secure the wallet password file
    sudo chmod 600 /etc/zano-wallet-password

    # Enable and start services
    sudo systemctl daemon-reload
    sudo systemctl enable zanod.service
    sudo systemctl enable tt-miner.service
    sudo systemctl enable zano-pos-mining.service

    log "Systemd services created and enabled!"
}

# Main installation routine
main() {
    clear
    echo -e "${BLUE}===== Zano Wallet, Miner, and Staking Setup =====${NC}"
    
    # Check for sudo
    if [ "$(id -u)" = "0" ]; then
        error "Please do not run this script as root. Use sudo only for specific commands."
    fi

    # Confirm before proceeding
    read -p "This script will install Zano wallet, miner, and set up staking as system services. Continue? (y/n): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        error "Installation cancelled by user."
    fi

    # Install dependencies
    install_dependencies
    
    # Download Zano components
    download_zano_components
    
    # Create wallet
    create_zano_wallet
    
    # Setup miner
    setup_tt_miner

    # Create systemd services
    create_systemd_services

    log "Zano Wallet, Miner, and Staking Setup Completed!"
    echo -e "${YELLOW}Important:${NC}"
    echo "1. Wallet details saved in: ~/zano-wallet-backup/wallet-details.txt"
    echo "2. Systemd services created:"
    echo "   - zanod.service (Zano Daemon)"
    echo "   - tt-miner.service (GPU Mining)"
    echo "   - zano-pos-mining.service (PoS Staking)"
    echo -e "${RED}IMPORTANT: Securely backup your wallet details file!${NC}"
    echo -e "${BLUE}Recommended: Transfer some ZANO to your wallet to start staking${NC}"
    
    # Prompt to start services
    read -p "Would you like to start the services now? (y/n): " START_SERVICES
    if [[ $START_SERVICES =~ ^[Yy]$ ]]; then
        sudo systemctl start zanod.service
        sudo systemctl start tt-miner.service
        sudo systemctl start zano-pos-mining.service
        log "Services started!"
    fi
}

# Run the main function
main