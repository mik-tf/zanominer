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

This bash script provides a comprehensive, automated setup for Zano blockchain enthusiasts, enabling easy installation of:
- Zano CLI Wallet
- GPU Mining
- Proof of Stake (PoS) Staking
- Systemd Services for automated management

## Prerequisites

- Ubuntu Desktop (recommended version 22.04 LTS or later)
- NVIDIA GPU with CUDA support
- Sudo access
- Basic terminal familiarity

## Features

- 🔒 Secure wallet creation
- 💻 Automatic dependency installation
- ⛏️ GPU mining setup with TT-Miner
- 💰 Proof of Stake mining configuration
- 🚀 Systemd services for seamless background operation

## Versions Included

- Zano CLI Wallet: v1.5.0.143
- TT-Miner: 2023.1.0

## Installation Steps

1. **Run the Script**
   ```bash
   bash zano_setup.sh
   ```

2. **Follow Interactive Prompts**
   - Choose wallet name
   - Optional: Configure separate mining reward address
   - Decide on service startup

## What the Script Does

### Dependencies
- Installs required system packages
- Sets up NVIDIA CUDA toolkit
- Installs NVIDIA drivers

### Wallet Creation
- Generates a new Zano wallet
- Creates secure, randomized passwords
- Saves wallet details in a secure backup location

### Mining & Staking Setup
- Downloads and configures TT-Miner
- Sets up systemd services for:
  - Zano Blockchain Daemon
  - GPU Mining
  - Proof of Stake Mining

## Security Considerations

- Wallet details are saved in `~/zano-wallet-backup/wallet-details.txt`
- File permissions are restricted
- Wallet password stored securely for PoS mining

## Systemd Services

- `zanod.service`: Zano Blockchain Daemon
- `tt-miner.service`: GPU Mining
- `zano-pos-mining.service`: Proof of Stake Mining

## Post-Installation

- Transfer ZANO to your wallet to start staking
- Securely backup your wallet details file
- Monitor services using `systemctl status <service-name>`

## Troubleshooting

- Ensure NVIDIA drivers are compatible
- Check system logs: `journalctl -u zanod.service`
- Verify wallet synchronization
- Confirm mining and staking connectivity

## Disclaimer

- Use at your own risk
- Always backup wallet information
- This script is community-supported

## Contributions

Contributions, issues, and feature requests are welcome!

## License

This work is under the [Apache 2.0 license](./LICENSE).