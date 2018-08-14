#!/bin/bash

user=$(whoami)
if [ $user != "root" ]; then
  echo "Please run as root."
  exit 1
fi

# POSTGRESQL
echo "Installing PostgreSQL tools..."
sudo apt install postgresql-client-common;
sudo touch /etc/apt/sources.list.d/pgdg.list;
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >> /etc/apt/sources.list.d/pgdg.list;
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -;
sudo apt-get update;
sudo apt-get install postgresql-10;
echo "Installed PostgreSQL tools: OK."

