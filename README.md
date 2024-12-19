<h1> Zano Blockchain Mining and Staking Script for Ubuntu Nvidia GPU Node </h1>

<h2>Table of Contents</h2>

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Features](#features)
- [Versions Included](#versions-included)
- [Installation Steps](#installation-steps)
- [What the Script Does](#what-the-script-does)
  - [Dependencies](#dependencies)
  - [Wallet Creation](#wallet-creation)
  - [Mining \& Staking Setup](#mining--staking-setup)
- [Security Considerations](#security-considerations)
- [Systemd Services](#systemd-services)
- [Post-Installation](#post-installation)
- [Troubleshooting](#troubleshooting)
- [Disclaimer](#disclaimer)
- [Contributions](#contributions)
- [License](#license)

---

## Introduction

A comprehensive setup script for Zano wallet, mining, and staking on Ubuntu with NVIDIA GPUs. This script automates the entire process of setting up a Zano node including wallet creation, GPU mining, and PoS staking.

## Features

- Full Zano node setup
- Automatic wallet creation with secure password management
- GPU mining configuration with TT-Miner
- Proof of Stake (PoS) mining setup
- Systemd service integration
- Installation in system path for easy access
- Service management commands

## Requirements

- Ubuntu Desktop 24.04
- NVIDIA GPU
- Sudo privileges
- Internet connection

## Installation

```bash
# Download the script
wget https://raw.githubusercontent.com/Mik-TF/zanominer/main/zanominer.sh

# Install in system path
bash zanominer.sh install
```

## Set Up the Miner

```bash
# Build the miner setup
zanominer build
```

## Usage

```bash
zanominer [COMMAND]
```

### Available Commands

- `install` - Install the script in system path
- `uninstall` - Remove the script from system path
- `build` - Run full installation and setup
- `show_services` - Display status of all Zano services
- `start` - Start all Zano services
- `stop` - Stop all Zano services
- `restart` - Restart all Zano services
- `help` - Show help message

### Examples

```bash
# Check services status
zanominer show_services

# Remove script from path
zanominer uninstall
```

## Service Management

The script creates and manages three systemd services:
1. `zanod.service` - Zano blockchain daemon
2. `tt-miner.service` - GPU mining service
3. `zano-pos-mining.service` - PoS staking service

### Control Services

```bash
zanominer start    # Start all services
zanominer stop     # Stop all services
zanominer restart  # Restart all services
```

## Security

- Wallet details are saved in `~/zano-project/wallet-details.txt`
- File permissions are set to 600 (user read/write only)
- Passwords are stored securely
- Service files use appropriate permissions

## Important Notes

- Backup your wallet details file immediately after creation
- Transfer ZANO to your wallet to begin staking
- Monitor mining and staking progress through service logs
- Keep your system updated and secured

## Troubleshooting

If you encounter issues:
1. Check service status: `zanominer services`
2. View service logs: `journalctl -u [service-name]`
3. Ensure NVIDIA drivers are properly installed
4. Verify wallet is properly funded for staking

## License

Apache License 2.0

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues, questions, or contributions, please visit:
[GitHub Repository](https://github.com/Mik-TF/zanominer)