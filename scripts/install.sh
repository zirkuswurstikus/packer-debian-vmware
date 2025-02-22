#!/bin/bash
set -e
set -u
set -o pipefail
set -x  # Enable command tracing
IFS=$'\n\t'

# Main script
echo "Starting installation script..."
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Environment variables:"
env

# Check for sudo
echo "Checking for sudo..."
command -v sudo || { echo "sudo not found"; exit 1; }

# Update system
echo "Upgrading system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# Install packages
echo "Installing additional packages..."
sudo apt-get install -y \
  curl \
  apt-transport-https \
  gpg \
  openssl \
  net-tools \
  unzip

# Install VMware Tools
echo "Installing VMware Tools..."
sudo apt-get install -y open-vm-tools

# Cleanup
echo "Cleaning up..."
sudo apt-get clean -y
sudo apt-get autoclean -y
sudo apt-get autoremove -y

echo "Zeroing free space..."
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

echo "Clearing bash history..."
cat /dev/null > ~/.bash_history

sync
echo "Shrinking VMware disk..."
sudo vmware-toolbox-cmd disk shrink /

echo "Installation script completed."
