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
ZANO_PREFIX_URL="https://build.zano.org/builds/"
ZANO_IMAGE_FILENAME="zano-linux-x64-develop-v2.0.1.367[d63feec].AppImage"
ZANO_URL=${ZANO_PREFIX_URL}${ZANO_IMAGE_FILENAME}
REWARD_ADDRESS=""
WALLET_PASSWORD=""
WALLET_NAME=""
TT_MINER_VERSION="2023.1.0"
STRATUM_PORT="11555"
POS_RPC_PORT="50005"
ZANOD_PID=""
ZANO_DIR="$HOME/zano-project"

# Help function
show_help() {
    echo -e "${BLUE}===== Zano Miner Script Help =====${NC}"
    echo -e "Usage: bash zanominer.sh [COMMAND]"
    echo
    echo "Commands:"
    echo -e "${GREEN}  install${NC}       - Install the script in path"
    echo -e "${GREEN}  uninstall${NC}     - Uninstall the script in path"
    echo -e "${GREEN}  help${NC}          - Show this help message"
    echo -e "${GREEN}  build${NC}         - Run full installation and setup"
    echo -e "${GREEN}  show_services${NC} - Show status of all Zano services"
    echo -e "${GREEN}  start${NC}         - Start all Zano services"
    echo -e "${GREEN}  stop${NC}          - Stop all Zano services"
    echo -e "${GREEN}  restart${NC}       - Restart all Zano services"
    echo -e "${GREEN}  help${NC}          - Show this help message"
    echo
    echo "Examples:"
    echo "  bash zanominer.sh build          # Run full installation"
    echo "  bash zanominer.sh show_services  # Check services status"
    echo
    echo "Requirements:"
    echo "- Ubuntu Desktop 24.04"
    echo "- NVIDIA GPU"
    echo "- Sudo privileges"
    echo
    echo "Notes:"
    echo "- The build command will install all dependencies and set up mining"
    echo "- Service commands require the initial build to be completed"
    echo "- Wallet details are saved in $ZANO_DIR/wallet-details.txt"
    echo
    echo "License: Apache 2.0"
    echo "For issues or more information, visit:"
    echo "Reference: https://github.com/Mik-TF/zanominer"
}

# Command line argument handling
handle_command() {
    case "$1" in
        build)
            main
            exit 0
            ;;
        show_services)
            check_services_status
            exit 0
            ;;
        install)
            install
            exit 0
            ;;
        uninstall)
            uninstall
            exit 0
            ;;
        start)
            start_services
            exit 0
            ;;
        stop)
            stop_services
            exit 0
            ;;
        restart)
            restart_services
            exit 0
            ;;
        help)
            show_help
            exit 0
            ;;
        *)
            show_help
            exit 0
            ;;
    esac
}

# Service management functions
check_services_status() {
    echo -e "${BLUE}===== Zano Services Status =====${NC}"
    for service in zanod tt-miner zano-pos-mining; do
        status=$(systemctl is-active $service.service)
        if [ "$status" = "active" ]; then
            echo -e "${GREEN}● $service.service is running${NC}"
        else
            echo -e "${RED}○ $service.service is $status${NC}"
        fi
        echo "---"
        systemctl status $service.service --no-pager | grep -A 2 "Active:"
        echo
    done
}

start_services() {
    log "Starting all Zano services..."
    sudo systemctl start zanod.service
    sleep 10
    sudo systemctl start tt-miner.service
    sudo systemctl start zano-pos-mining.service
    check_services_status
}

stop_services() {
    log "Stopping all Zano services..."
    sudo systemctl stop zano-pos-mining.service
    sudo systemctl stop tt-miner.service
    sudo systemctl stop zanod.service
    check_services_status
}

restart_services() {
    log "Restarting all Zano services..."
    stop_services
    sleep 5
    start_services
}

# Function to install the script
install() {
    echo
    echo -e "${GREEN}Installing Zano Miner...${NC}"
    if sudo -v; then
        sudo cp "$0" /usr/local/bin/zanominer
        sudo chown root:root /usr/local/bin/zanominer
        sudo chmod 755 /usr/local/bin/zanominer

        echo
        echo -e "${PURPLE}zanominer has been installed successfully.${NC}"
        echo -e "You can now use ${GREEN}zanominer${NC} command from anywhere."
        echo
        echo -e "Use ${BLUE}zanominer help${NC} to see the commands."
        echo
    else
        echo -e "${RED}Error: Failed to obtain sudo privileges. Installation aborted.${NC}"
        exit 1
    fi
}

# Function to uninstall the script
uninstall() {
    echo
    echo -e "${GREEN}Uninstalling zanominer...${NC}"
    if sudo -v; then
        sudo rm -f /usr/local/bin/zanominer
        echo -e "${PURPLE}zanominer has been uninstalled successfully.${NC}"
        echo
    else
        echo -e "${RED}Error: Failed to obtain sudo privileges. Uninstallation aborted.${NC}"
        exit 1
    fi
}

# Logging functions
log() {
    echo -e "${GREEN}[ZANO SETUP]${NC} $1"
    sleep 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    sleep 1
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    sleep 1
    exit 1
}

# Daemon management functions
start_zanod() {
    log "Starting Zano daemon in background..."
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"
    ${ZANO_DIR}/zanod > zanod_output.log 2>&1 &
    ZANOD_PID=$!
    log "Zano daemon started with PID: $ZANOD_PID"
    log "Entering sleep for 30 seconds to let the blockchain sync."
    # Wait for process to actually start
    sleep 5
    if ! ps -p $ZANOD_PID > /dev/null; then
        error "Failed to start zanod process"
    fi
    sleep 25  # Additional wait time for blockchain sync
}

stop_zanod() {
    if [ ! -z "$ZANOD_PID" ] && ps -p $ZANOD_PID > /dev/null; then
        log "Stopping Zanod (PID: $ZANOD_PID)"
        kill $ZANOD_PID
        wait $ZANOD_PID 2>/dev/null || true
    else
        log "No running Zanod process found with stored PID"
        # Fallback: Try to kill any running zanod process
        pkill -f zanod || true
    fi
}

# Dependency check and installation
install_dependencies() {
    log "Checking and installing system dependencies..."
    
    # Update package lists
    sudo apt update

    # Check for NVIDIA GPU
    if lspci | grep -i nvidia > /dev/null; then
        log "NVIDIA GPU detected. Installing NVIDIA drivers and CUDA..."
        
        # Install NVIDIA drivers
        sudo ubuntu-drivers autoinstall
        
        # Install CUDA toolkit
        sudo apt install -y nvidia-cuda-toolkit
        
        # Verify CUDA installation
        if ! command -v nvcc &> /dev/null; then
            warn "CUDA installation might have failed. Please check manually."
        else
            log "CUDA installation verified: $(nvcc --version | head -n1)"
        fi
    else
        warn "No NVIDIA GPU detected. Mining performance may be limited."
    fi

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
    log "Starting download of Zano components..."
    
    # Create Zano directory
    mkdir -p "$ZANO_DIR"
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"
    log "All files will be stored in ${ZANO_DIR}"

    # Verify download
    if [ ! -f ${ZANO_IMAGE_FILENAME} ]; then
        log "Downloading Zano CLI Wallet..."
        wget $ZANO_URL || error "Failed to download Zano CLI Wallet"
    fi
   
    log "Zano CLI Wallet file has been downloaded..."

    # Allow execute and Extract
    chmod +x $ZANO_IMAGE_FILENAME
    ${ZANO_DIR}/$ZANO_IMAGE_FILENAME --appimage-extract || error "Failed to extract AppImage"
    
    # Move programs to working directory and clean up
    mv "$ZANO_DIR/squashfs-root/usr/bin/simplewallet" "$ZANO_DIR/"
    mv "$ZANO_DIR/squashfs-root/usr/bin/zanod" "$ZANO_DIR/"
    rm -r "$ZANO_DIR/squashfs-root"
}

create_zano_wallet() {
    log "Creating Zano Wallet..."

    # Prompt for wallet name
    read -p "Enter a name for your wallet (e.g., myzanowallet): " WALLET_NAME
    
    # Prompt for password preference
    read -p "Do you want to set your own wallet password? (y/n): " SET_OWN_PASSWORD
    
    if [[ $SET_OWN_PASSWORD =~ ^[Yy]$ ]]; then
        # Ask for password with confirmation
        while true; do
            read -s -p "Enter your wallet password: " WALLET_PASSWORD
            echo
            read -s -p "Confirm your wallet password: " WALLET_PASSWORD_CONFIRM
            echo
            
            if [ "$WALLET_PASSWORD" = "$WALLET_PASSWORD_CONFIRM" ]; then
                break
            else
                warn "Passwords do not match. Please try again."
            fi
        done
    else
        # Generate secure password
        log "Generating random secure wallet password"
        WALLET_PASSWORD=$(pwgen -s 16 1)
    fi

    # Prompt for seed password preference
    read -p "Do you want to set your own seed password? (y/n): " SET_OWN_SEED_PASSWORD
    
    if [[ $SET_OWN_SEED_PASSWORD =~ ^[Yy]$ ]]; then
        # Ask for seed password with confirmation
        while true; do
            read -s -p "Enter your seed password: " SEED_PASSWORD
            echo
            read -s -p "Confirm your seed password: " SEED_PASSWORD_CONFIRM
            echo
            
            if [ "$SEED_PASSWORD" = "$SEED_PASSWORD_CONFIRM" ]; then
                break
            else
                warn "Passwords do not match. Please try again."
            fi
        done
    else
        # Generate secure seed password
        log "Generating random secure seed password"
        SEED_PASSWORD=$(pwgen -s 16 1)
    fi

    log "Generating wallet: ${WALLET_NAME}.wallet"
    
    # Start daemon
    start_zanod

    # Create wallet (non-interactive)
    ${ZANO_DIR}/simplewallet --generate-new-wallet=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
EOF

    # Open wallet to show address
    WALLET_ADDRESS=$(${ZANO_DIR}/simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
address
exit
EOF
)

    # Extract wallet address
    WALLET_ADDRESS=$(echo "$WALLET_ADDRESS" | grep -oP 'Zx[a-zA-Z0-9]+' | head -n 1)

    log "Wallet created successfully!"
    echo -e "${BLUE}Wallet Address: ${WALLET_ADDRESS}${NC}"

    # Save seed phrase
    SEED_PHRASE=$(${ZANO_DIR}/simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
show_seed
${WALLET_PASSWORD}
${SEED_PASSWORD}
${SEED_PASSWORD}
exit
EOF
)

    # Modified extraction:
    SEED_PHRASE=$(echo "$SEED_PHRASE" | grep -A1 "Remember, restoring a wallet from Secured Seed can only be done if you know its password." | tail -n1 | sed 's/\[Zano wallet.*$//')

    # Stop daemon
    stop_zanod

    # Save wallet details securely
    echo "Wallet Name: ${WALLET_NAME}" > "$ZANO_DIR/wallet-details.txt"
    echo "Wallet Address: ${WALLET_ADDRESS}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Wallet Password: ${WALLET_PASSWORD}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Seed Password: ${SEED_PASSWORD}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Seed Phrase: ${SEED_PHRASE}" >> "$ZANO_DIR/wallet-details.txt"

    chmod 600 "$ZANO_DIR/wallet-details.txt"
}

# Setup TT-Miner
setup_tt_miner() {
    log "Setting up TT-Miner..."
    
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"

    # Verify download
    if [ ! -f TT-Miner-${TT_MINER_VERSION}.tar.gz ]; then
        log "Downloading Miner"
        wget https://github.com/TrailingStop/TT-Miner-release/releases/download/${TT_MINER_VERSION}/TT-Miner-${TT_MINER_VERSION}.tar.gz
    fi

    # Extract TT-Miner
    tar -xf TT-Miner-${TT_MINER_VERSION}.tar.gz
    chmod +x TT-Miner
}

# Create systemd service files
create_systemd_services() {
    log "Creating systemd service files..."

    # Create wallet password file first
    echo "${WALLET_PASSWORD}" | sudo tee /etc/zano-wallet-password > /dev/null
    sudo chmod 600 /etc/zano-wallet-password

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
WorkingDirectory=${ZANO_DIR}
ExecStart=${ZANO_DIR}/zanod --stratum --stratum-miner-address=${WALLET_ADDRESS} --stratum-bind-port=${STRATUM_PORT}
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
WorkingDirectory=${ZANO_DIR}/TT-Miner
ExecStart=${ZANO_DIR}/TT-Miner/TT-Miner -luck -coin ZANO -u zano-miner -o 127.0.0.1:${STRATUM_PORT}
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
WorkingDirectory=${ZANO_DIR}
ExecStart=${ZANO_DIR}/simplewallet --wallet-file=${WALLET_NAME}.wallet --password=${WALLET_PASSWORD} --rpc-bind-port=${POS_RPC_PORT} --do-pos-mining --log-level=0 --log-file=${ZANO_DIR}/pos-mining.log --deaf ${REWARD_OPTION}
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
    echo
    echo -e "${BLUE}===== Zano Wallet, Miner, and Staking Setup for Ubuntu NVIDIA GPU Node =====${NC}"
    echo
    # Check for sudo
    if [ "$(id -u)" = "0" ]; then
        error "Please do not run this script as root. Use sudo only for specific commands."
    fi

    # Confirm before proceeding
    read -p "This script will install Zano wallet, miner, and set up staking as system services for a Ubuntu NVIDIA GPU node. Continue? (y/n): " CONFIRM
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
    echo "1. Wallet details saved in: $ZANO_DIR/wallet-details.txt"
    echo "2. Systemd services created:"
    echo "   - zanod.service (Zano Daemon)"
    echo "   - tt-miner.service (GPU Mining)"
    echo "   - zano-pos-mining.service (PoS Staking)"
    echo -e "${RED}IMPORTANT: Securely backup your wallet details file!${NC}"
    echo -e "${BLUE}Recommended: Transfer some ZANO to your wallet to start staking${NC}"
    
    # Prompt to start services
    read -p "Would you like to start the services now? (y/n): " START_SERVICES
    if [[ $START_SERVICES =~ ^[Yy]$ ]]; then
        start_services
    fi
}

# Handle command line arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
else
    handle_command "$1"
fi
exit 0