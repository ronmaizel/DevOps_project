#!/bin/bash

# static vars
REPO_URL="https://github.com/ronmaizel/DevOps_project.git"
PROJECT_DIR="/opt/DevOps_project"
NFS_service_IP="192.168.10.10"
NFS_REMOTE_PATH="/media"
NFS_MOUNT_PATH="/media"
APP_PORT=8080
WEB_PORT=80

# install packages
echo "Installing necessary packages."
dnf -y install curl
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh
dnf install -y docker-compose-plugin python3 python3-pip git nfs-common

# add current user to docker group
usermod -aG docker $(whoami)

# open relevant ports
firewall-cmd --add-port={80,5342,2049,8080}/tcp

# clone git repo
echo "Cloning project repository."
cd /opt
git clone "$REPO_URL"
if [ -d $PROJECT_DIR ]; then
  echo "Clone complete"
fi

# mount NFS
echo "Mounting NFS share."
mkdir -p "$NFS_MOUNT_PATH"
mount -t nfs "$NFS_service_IP:$NFS_REMOTE_PATH" "$NFS_MOUNT_PATH"
echo "$NFS_service_IP:$NFS_REMOTE_PATH $NFS_MOUNT_PATH nfs defaults 0 0" >> /etc/fstab

# start environment
cd $PROJECT_DIR
echo "Building and starting services."
docker compose up -d
echo "Trial environment ready."

# health checks
echo "Performing health checks."
if curl -s http://localhost:$WEB_PORT | grep -q '200'; then
    echo "Nginx web service is running."
else
    echo "Nginx web service is not responding. Check container logs."
fi

if curl -s http://localhost:$APP_PORT | grep -q '200'; then
    echo "FastAPI app service is running."
else
    echo "FastAPI app service is not responding. Check container logs."
fi

if docker exec db pg_isready -U postgres &>/dev/null; then
    echo "PostgreSQL service is running."
else
    echo "PostgreSQL service is not responding. Check container logs."
fi
