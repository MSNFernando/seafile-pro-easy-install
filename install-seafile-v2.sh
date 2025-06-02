#!/bin/bash

set -e

echo "🔧 Installing prerequisites..."
sudo apt update
sudo apt install -y git curl jq nfs-common s3cmd

# --- Install Docker ---
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | sudo bash
  sudo usermod -aG docker $USER
fi

# --- Install Docker Compose plugin ---
if ! command -v docker compose &> /dev/null; then
  echo "📦 Installing Docker Compose plugin..."
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64 \
    -o docker-compose
  sudo mv docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

# --- Clone repo ---
REPO_NAME="seafile-pro-docker"
GITHUB_USERNAME="MSNFernando"
REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

if [ ! -d "$REPO_NAME" ]; then
  echo "📥 Cloning SeaFile Pro deployment repo..."
  git clone "$REPO_URL"
fi

cd "$REPO_NAME"

cp seafile.env .env

echo "Please update the .env file with the correct information!"
echo "run sudo docker compose up -d --build to start seafile"
