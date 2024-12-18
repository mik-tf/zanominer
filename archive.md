# Stop services
sudo systemctl stop zanod.service
sudo systemctl stop tt-miner.service
sudo systemctl stop zano-pos-mining.service

# Disable services
sudo systemctl disable zanod.service
sudo systemctl disable tt-miner.service
sudo systemctl disable zano-pos-mining.service

# Remove service files
sudo rm /etc/systemd/system/zanod.service
sudo rm /etc/systemd/system/tt-miner.service
sudo rm /etc/systemd/system/zano-pos-mining.service

# Reload systemd
sudo systemctl daemon-reload

# Verify removal
systemctl status zanod.service
systemctl status tt-miner.service
systemctl status zano-pos-mining.service


---

# Backup lines

./zanod &
./zanod > /dev/null 2>&1 &