#!/bin/bash

# Comprehensive Zano Wallet, Miner, and Staking Setup Script with Systemd
# For Ubuntu Desktop
# Supports full installation: dependencies, wallet creation, mining, and staking as system services
# This script automates the complete setup process with upfront user input collection

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration Variables
# URLs and filenames for Zano components
ZANO_PREFIX_URL="https://build.zano.org/builds/"
ZANO_IMAGE_FILENAME="zano-linux-x64-develop-v2.0.1.367[d63feec].AppImage"
ZANO_URL=${ZANO_PREFIX_URL}${ZANO_IMAGE_FILENAME}

# User input variables - these will be populated by collect_user_inputs()
REWARD_ADDRESS=""
WALLET_PASSWORD=""
WALLET_NAME=""
SEED_PASSWORD=""
SET_OWN_PASSWORD=""
SET_OWN_SEED_PASSWORD=""
USE_SEPARATE_REWARD=""
START_SERVICES_AFTER_INSTALL=""
REWARD_OPTION=""

# Mining and network configuration
TT_MINER_VERSION="2023.1.0"
STRATUM_PORT="11555"
POS_RPC_PORT="50005"
ZANOD_PID=""
ZANO_DIR="$HOME/zano-project"

# Function to collect all user inputs upfront
# This consolidates all user interaction at the beginning of the script
collect_user_inputs() {
    echo -e "${BLUE}===== User Configuration =====${NC}"
    echo "This section will collect all necessary information for your Zano setup."
    echo "Please provide the following details:"
    echo
    
    # Wallet name input
    read -p "Enter a name for your wallet (e.g., myzanowallet): " WALLET_NAME
    
    # Wallet password setup
    read -p "Do you want to set your own wallet password? (y/n): " SET_OWN_PASSWORD
    if [[ $SET_OWN_PASSWORD =~ ^[Yy]$ ]]; then
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
        # Generate random password if user doesn't want to set their own
        WALLET_PASSWORD=$(pwgen -s 16 1)
        echo "A secure random password has been generated for your wallet."
    fi

    # Seed password setup
    read -p "Do you want to set your own seed password? (y/n): " SET_OWN_SEED_PASSWORD
    if [[ $SET_OWN_SEED_PASSWORD =~ ^[Yy]$ ]]; then
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
        # Generate random seed password if user doesn't want to set their own
        SEED_PASSWORD=$(pwgen -s 16 1)
        echo "A secure random seed password has been generated."
    fi

    # Mining rewards address configuration
    read -p "Do you want to use a separate address for mining rewards? (y/n): " USE_SEPARATE_REWARD
    if [[ $USE_SEPARATE_REWARD =~ ^[Yy]$ ]]; then
        read -p "Enter the separate reward address: " REWARD_ADDRESS
        REWARD_OPTION="--pos-mining-reward-address=${REWARD_ADDRESS}"
    else
        REWARD_OPTION=""
    fi

    # Service autostart configuration
    read -p "Would you like to start the services after installation? (y/n): " START_SERVICES_AFTER_INSTALL

    echo -e "${GREEN}All user inputs collected successfully. Starting installation...${NC}"
    echo
    # Brief pause to let user read the confirmation
    sleep 2
}

# Help function - Displays usage information and available commands
show_help() {
    echo -e "${BLUE}===== Zano Miner Script Help =====${NC}"
    echo -e "Usage: bash zanominer.sh [COMMAND]"
    echo
    echo "Commands:"
    echo -e "${GREEN}  install${NC}       - Install the script in path"
    echo -e "${GREEN}  uninstall${NC}     - Uninstall the script in path"
    echo -e "${GREEN}  help${NC}          - Show this help message"
    echo -e "${GREEN}  build${NC}         - Run full installation and setup"
    echo -e "${GREEN}  status${NC}        - Show status of all Zano services"
    echo -e "${GREEN}  start${NC}         - Start all Zano services"
    echo -e "${GREEN}  stop${NC}          - Stop all Zano services"
    echo -e "${GREEN}  restart${NC}       - Restart all Zano services"
    echo
    echo "Examples:"
    echo "  bash zanominer.sh build     # Run full installation"
    echo "  bash zanominer.sh status  # Check services status"
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
# Processes the script commands and directs to appropriate functions
handle_command() {
    case "$1" in
        build)
            main
            exit 0
            ;;
        status)
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
# Checks the status of all Zano-related services
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

# Starts all Zano services in the correct order
start_services() {
    log "Starting all Zano services..."
    sudo systemctl start zanod.service
    sleep 10  # Wait for daemon to initialize
    sudo systemctl start tt-miner.service
    sudo systemctl start zano-pos-mining.service
    check_services_status
}

# Stops all Zano services in the correct order
stop_services() {
    log "Stopping all Zano services..."
    sudo systemctl stop zano-pos-mining.service
    sudo systemctl stop tt-miner.service
    sudo systemctl stop zanod.service
    check_services_status
}

# Restarts all Zano services
restart_services() {
    log "Restarting all Zano services..."
    stop_services
    sleep 5  # Wait for clean shutdown
    start_services
}

# Function to install the script system-wide
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

        # Stop services if running
        if systemctl is-active --quiet zanod.service || \
           systemctl is-active --quiet tt-miner.service || \
           systemctl is-active --quiet zano-pos-mining.service; then
            echo "Stopping mining services..."
            stop_services
        fi

        # Remove systemd services
        echo "Removing systemd services..."
        sudo systemctl disable zanod.service tt-miner.service zano-pos-mining.service 2>/dev/null
        sudo rm -f /etc/systemd/system/zanod.service
        sudo rm -f /etc/systemd/system/tt-miner.service
        sudo rm -f /etc/systemd/system/zano-pos-mining.service
        sudo systemctl daemon-reload

        sudo rm -f /usr/local/bin/zanominer

        # Ask user if they want to remove mining data
        read -p "Do you want to remove all Zano project directory? (y/n): " REMOVE_DATA
        if [[ $REMOVE_DATA =~ ^[Yy]$ ]]; then
            echo "Removing all mining data..."
            rm -rf "$ZANO_DIR"
        else
            echo "Zano project preserved in $ZANO_DIR"
        fi

        echo -e "${GREEN}Uninstallation completed successfully.${NC}"

    else
        echo -e "${RED}Error: Failed to obtain sudo privileges. Uninstallation aborted.${NC}"
        exit 1
    fi
}

# Logging functions for consistent output formatting
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
# Starts the Zano daemon in background
start_zanod() {
    log "Starting Zano daemon in background..."
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"
    ${ZANO_DIR}/zanod > zanod_output.log 2>&1 &
    ZANOD_PID=$!
    log "Zano daemon started with PID: $ZANOD_PID"
    log "Entering sleep for 30 seconds to let the blockchain sync."
    sleep 5
    if ! ps -p $ZANOD_PID > /dev/null; then
        error "Failed to start zanod process"
    fi
    sleep 25  # Additional wait time for blockchain sync
}

# Stops the Zano daemon safely
stop_zanod() {
    if [ ! -z "$ZANOD_PID" ] && ps -p $ZANOD_PID > /dev/null; then
        log "Stopping Zanod (PID: $ZANOD_PID)"
        kill $ZANOD_PID
        wait $ZANOD_PID 2>/dev/null || true
    else
        log "No running Zanod process found with stored PID"
        pkill -f zanod || true
    fi
}

# Dependency check and installation
# Installs all required system packages and NVIDIA drivers
install_dependencies() {
    log "Checking and installing system dependencies..."
    
    # Update package lists
    sudo apt update

    # Check for NVIDIA GPU and install appropriate drivers
    if lspci | grep -i nvidia > /dev/null; then
        log "NVIDIA GPU detected. Checking NVIDIA drivers and CUDA..."
        
        if ! nvidia-smi &>/dev/null; then
            log "Installing NVIDIA drivers..."
            sudo ubuntu-drivers autoinstall
        else
            log "NVIDIA drivers are already installed: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
        fi
        
        if ! command -v nvcc &>/dev/null; then
            log "Installing CUDA toolkit..."
            sudo apt install -y nvidia-cuda-toolkit
        else
            log "CUDA toolkit is already installed: $(nvcc --version | head -n1)"
        fi
        
        if ! command -v nvcc &> /dev/null; then
            warn "CUDA installation might have failed. Please check manually."
        else
            log "CUDA installation verified: $(nvcc --version | head -n1)"
        fi
    else
        warn "No NVIDIA GPU detected. Mining performance may be limited."
    fi

    # Install essential system dependencies
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

    # Install password generator if not present
    if ! command -v pwgen &> /dev/null; then
        sudo apt install -y pwgen
    fi
}

# Download and extract Zano components
download_zano_components() {
    log "Starting download of Zano components..."
    
    # Create and enter Zano directory
    mkdir -p "$ZANO_DIR"
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"
    log "All files will be stored in ${ZANO_DIR}"

    # Skip download if components already exist
    if [ -f "$ZANO_DIR/simplewallet" ] && [ -f "$ZANO_DIR/zanod" ]; then
        log "Zano components already present, skipping download and extraction..."
        return
    fi

    # Download Zano CLI wallet if not present
    if [ ! -f ${ZANO_IMAGE_FILENAME} ]; then
        log "Downloading Zano CLI Wallet..."
        wget $ZANO_URL || error "Failed to download Zano CLI Wallet"
    fi
   
    log "Zano CLI Wallet file has been downloaded..."

    # Extract AppImage contents
    chmod +x $ZANO_IMAGE_FILENAME
    ${ZANO_DIR}/$ZANO_IMAGE_FILENAME --appimage-extract || error "Failed to extract AppImage"
    
    # Move required binaries to working directory and cleanup
    mv "$ZANO_DIR/squashfs-root/usr/bin/simplewallet" "$ZANO_DIR/"
    mv "$ZANO_DIR/squashfs-root/usr/bin/zanod" "$ZANO_DIR/"
    rm -r "$ZANO_DIR/squashfs-root"
}

# Create and configure Zano wallet
create_zano_wallet() {
    log "Creating Zano Wallet..."
    
    log "Generating wallet: ${WALLET_NAME}.wallet"
    
    # Start daemon for wallet creation
    start_zanod

    # Create new wallet using collected password
    ${ZANO_DIR}/simplewallet --generate-new-wallet=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
EOF

    # Get wallet address
    WALLET_ADDRESS=$(${ZANO_DIR}/simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
address
exit
EOF
)

    # Extract wallet address from output
    WALLET_ADDRESS=$(echo "$WALLET_ADDRESS" | grep -oP 'Zx[a-zA-Z0-9]+' | head -n 1)

    log "Wallet created successfully!"
    echo -e "${BLUE}Wallet Address: ${WALLET_ADDRESS}${NC}"

    # Get seed phrase
    SEED_PHRASE=$(${ZANO_DIR}/simplewallet --wallet-file=${WALLET_NAME}.wallet <<EOF
${WALLET_PASSWORD}
show_seed
${WALLET_PASSWORD}
${SEED_PASSWORD}
${SEED_PASSWORD}
exit
EOF
)

    # Extract seed phrase from output
    SEED_PHRASE=$(echo "$SEED_PHRASE" | grep -A1 "Remember, restoring a wallet from Secured Seed can only be done if you know its password." | tail -n1 | sed 's/\[Zano wallet.*$//')

    # Stop daemon after wallet creation
    stop_zanod

    # Save wallet details to secure file
    echo "Wallet Name: ${WALLET_NAME}" > "$ZANO_DIR/wallet-details.txt"
    echo "Wallet Address: ${WALLET_ADDRESS}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Wallet Password: ${WALLET_PASSWORD}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Seed Password: ${SEED_PASSWORD}" >> "$ZANO_DIR/wallet-details.txt"
    echo "Seed Phrase: ${SEED_PHRASE}" >> "$ZANO_DIR/wallet-details.txt"

    # Secure the wallet details file
    chmod 600 "$ZANO_DIR/wallet-details.txt"
}

# Setup TT-Miner for GPU mining
setup_tt_miner() {
    log "Setting up TT-Miner..."
    
    cd "$ZANO_DIR" || error "Failed to change to Zano directory"

    # Download TT-Miner if not present
    if [ ! -f TT-Miner-${TT_MINER_VERSION}.tar.gz ]; then
        log "Downloading Miner"
        wget https://github.com/TrailingStop/TT-Miner-release/releases/download/${TT_MINER_VERSION}/TT-Miner-${TT_MINER_VERSION}.tar.gz
    fi

    # Extract and set permissions
    tar -xf TT-Miner-${TT_MINER_VERSION}.tar.gz
    chmod +x TT-Miner
}

# Create service scripts for systemd services
create_service_scripts() {
    log "Creating service scripts..."
    
    # Create zanod daemon script
    sudo tee /usr/local/bin/run-zanod.sh > /dev/null << EOF
#!/bin/bash
cd ${ZANO_DIR}
./zanod --stratum --stratum-miner-address=${WALLET_ADDRESS} --stratum-bind-port=${STRATUM_PORT} --no-console
EOF

    # Create TT-Miner script
    sudo tee /usr/local/bin/run-tt-miner.sh > /dev/null << EOF
#!/bin/bash
cd ${ZANO_DIR}/TT-Miner
./TT-Miner -luck -coin ZANO -u miner -o 127.0.0.1:${STRATUM_PORT}
EOF

    # Create PoS Mining script
    sudo tee /usr/local/bin/run-pos-mining.sh > /dev/null << EOF
#!/bin/bash
cd ${ZANO_DIR}
./simplewallet --wallet-file=${WALLET_NAME}.wallet --password=${WALLET_PASSWORD} --rpc-bind-port=${POS_RPC_PORT} --do-pos-mining --log-level=0 --log-file=pos-mining.log --deaf ${REWARD_OPTION}
EOF

    # Set execute permissions
    sudo chmod +x /usr/local/bin/run-zanod.sh
    sudo chmod +x /usr/local/bin/run-tt-miner.sh
    sudo chmod +x /usr/local/bin/run-pos-mining.sh
}

# Create and configure systemd services
create_systemd_services() {
    # Create service scripts first
    create_service_scripts
    log "Creating systemd service files..."

    # Zano Daemon Systemd Service
    sudo tee /etc/systemd/system/zanod.service > /dev/null << EOF
[Unit]
Description=Zano Blockchain Daemon
After=network.target

[Service]
Type=simple
User=${USER}
ExecStart=/usr/local/bin/run-zanod.sh
StandardInput=null
StandardOutput=append:/var/log/zanod.log
StandardError=append:/var/log/zanod.error.log
Restart=always
RestartSec=10

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
ExecStart=/usr/local/bin/run-tt-miner.sh
StandardOutput=append:/var/log/tt-miner.log
StandardError=append:/var/log/tt-miner.error.log
Restart=always
RestartSec=10

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
ExecStart=/usr/local/bin/run-pos-mining.sh
StandardOutput=append:/var/log/zano-pos-mining.log
StandardError=append:/var/log/zano-pos-mining.error.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable services
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

    # Check if running as root
    if [ "$(id -u)" = "0" ]; then
        error "Please do not run this script as root. Use sudo only for specific commands."
    fi

    # Initial confirmation
    read -p "This script will install Zano wallet, miner, and set up staking as system services for a Ubuntu NVIDIA GPU node. Continue? (y/n): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        error "Installation cancelled by user."
    fi

    # Collect all user inputs at the start
    collect_user_inputs

    # Proceed with installation steps
    install_dependencies
    download_zano_components
    create_zano_wallet
    setup_tt_miner
    create_systemd_services

    # Installation complete message
    log "Zano Wallet, Miner, and Staking Setup Completed!"
    echo -e "${YELLOW}Important:${NC}"
    echo "1. Wallet details saved in: $ZANO_DIR/wallet-details.txt"
    echo "2. Systemd services created:"
    echo "   - zanod.service (Zano Daemon)"
    echo "   - tt-miner.service (GPU Mining)"
    echo "   - zano-pos-mining.service (PoS Staking)"
    echo -e "${RED}IMPORTANT: Securely backup your wallet details file!${NC}"
    echo -e "${BLUE}Recommended: Transfer some ZANO to your wallet to start staking${NC}"
    
    # Start services if requested during setup
    if [[ $START_SERVICES_AFTER_INSTALL =~ ^[Yy]$ ]]; then
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