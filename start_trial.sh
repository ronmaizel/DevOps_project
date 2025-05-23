#!/bin/bash

# static vars
REPO_URL="https://github.com/ronmaizel/DevOps_project.git"
PROJECT_DIR="/opt/trial_plan"
NFS_service_IP="192.168.10.10"
NFS_REMOTE_PATH="/media"
NFS_MOUNT_PATH="/media"
APP_PORT=8080
WEB_PORT=80

# install packages
echo "Installing necessary packages."
if ! command -v docker &> /dev/null; then
    yum install curl
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# clone git repo
echo "Cloning project repository."
if [ ! -d "$PROJECT_DIR" ]; then
    cd /opt
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# mount NFS
echo "Mounting NFS share."
sudo yum install -y nfs-common
sudo mkdir -p "$NFS_MOUNT_PATH"
sudo mount -t nfs "$NFS_service_IP:$NFS_REMOTE_PATH" "$NFS_MOUNT_PATH"

echo "$NFS_service_IP:$NFS_REMOTE_PATH $NFS_MOUNT_PATH nfs defaults 0 0" >> /etc/fstab


# start environment
echo "Building and starting services."
docker compose up -d
echo "Trial environment ready."

# health checks
echo "Performing health checks."

if curl -s http://localhost:$WEB_PORT | grep -q '200'; then
    echo "Nginx web service is running."
else
    echo "Nginx web service is not responding. Check container logs."
    exit 1
fi

if curl -s http://localhost:$APP_PORT | grep -q '200'; then
    echo "FastAPI app service is running."
else
    echo "FastAPI app service is not responding. Check container logs."
    exit 1
fi

if docker exec db pg_isready -U postgres &>/dev/null; then
    echo "PostgreSQL service is running."
else
    echo "PostgreSQL service is not responding. Check container logs."
    exit 1
fi

