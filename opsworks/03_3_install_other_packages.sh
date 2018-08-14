#!/bin/bash

user=$(whoami)
if [ $user != "root" ]; then
  echo "Please run as root."
  exit 1
fi


# OTHER PACKAGES
# pip upgrade
pip install --upgrade pip;
# AWS CLI tools
pip install awscli;
# csv toolkit
conda install csvkit
# process and resource monitoring
sudo apt-get install htop
