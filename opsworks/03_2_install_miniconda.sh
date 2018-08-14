#!/bin/bash

user=$(whoami)
if [ $user == "root" ]; then
  echo "Please do not run as root."
  exit 1
fi


# MINICONDA
echo "Installing Miniconda..."
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh;
chmod +x Miniconda3-latest-Linux-x86_64.sh;
sudo bash Miniconda3-latest-Linux-x86_64.sh;
echo "Installed Miniconda: OK."

# Add Miniconda path to bashrc
echo "export PATH=\"/opt/miniconda3/bin:\$PATH\"" >> ~/.bashrc;
source ~/.bashrc;
