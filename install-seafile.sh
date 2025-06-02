#!/bin/bash

set -e

echo "🔧 Installing prerequisites..."
sudo apt update
sudo apt install -y git curl jq

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

# --- Prompt for user input ---
read -p "🌐 Enter SeaFile server hostname (e.g. files.example.com): " SEAFILE_SERVER_HOSTNAME
read -p "📧 Enter admin email address: " SEAFILE_ADMIN_EMAIL
read -p "🪪 Enter your MinIO AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -p "🔐 Enter your MinIO AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
read -p "🪣 Enter your MinIO S3 bucket name: " S3_BUCKET

# --- Generate secure password ---
SEAFILE_ADMIN_PASSWORD=$(openssl rand -base64 18)
echo -e "SeaFile Admin Password:\n$SEAFILE_ADMIN_PASSWORD" > seafile_admin.txt
chmod 600 seafile_admin.txt

# --- Write seafile.env ---
cat <<EOF > seafile.env
# --- Admin config ---
SEAFILE_SERVER_HOSTNAME=$SEAFILE_SERVER_HOSTNAME
SEAFILE_ADMIN_EMAIL=$SEAFILE_ADMIN_EMAIL
SEAFILE_ADMIN_PASSWORD=$SEAFILE_ADMIN_PASSWORD

# --- MySQL password (used in compose file) ---
DB_ROOT_PASS=$(openssl rand -base64 16)

# --- S3-compatible MinIO backend ---
USE_S3_STORAGE=true
SEAFILE_CONF_IN_S3=false

AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

S3_ENDPOINT=10.30.15.242:9000
S3_USE_HTTPS=false
S3_VERIFY_CERT=false
S3_REGION=nz-west-2
S3_ADDRESSING_STYLE=path
S3_BUCKET=$S3_BUCKET
S3_STORAGE_CLASS=STANDARD
S3_MULTIPART_THRESHOLD=20
S3_UPLOAD_CHUNK_SIZE=10
EOF

echo "✅ Configuration complete."

# --- Start docker ---
echo "🚀 Starting SeaFile stack using Docker Compose..."
docker compose up -d

echo ""
echo "✅ SeaFile Pro is now running!"
echo "🌐 Access it at: http://$(hostname -I | awk '{print $1}')"
echo "📁 Admin credentials saved to: $(pwd)/seafile_admin.txt"
echo "🔑 Admin password: $SEAFILE_ADMIN_PASSWORD"
echo "🔑 Database password: $DB_ROOT_PASS"
