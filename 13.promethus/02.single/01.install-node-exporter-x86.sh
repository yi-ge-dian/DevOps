#!/bin/bash

# 色卡
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# 颜色打印函数
print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

function check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "Error: You must be root to run this script, please use root to install"
        exit 1
    fi
}

VERSION=1.11.1
ARCH=amd64
SOFTWARE=node_exporter-${VERSION}.linux-${ARCH}.tar.gz
URL=https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${SOFTWARE}
DOWNLOAD_DIR=/usr/local
BASE_DIR=/usr/local/node_exporter
DATA_DIR=/data/node_exporter/data
LOG_DIR=/data/node_exporter/log
ETC_DIR=/data/node_exporter/etc

function create_user() {
    if id node_exporter &>/dev/null; then
        print_colored "$BLUE" "User prometheus already exists"
    else
        print_colored "$BLUE" "Creating user prometheus..."
        useradd -r -s /sbin/nologin node_exporter
    fi
}

function download_node_exporter() {
    if [ -f ${DOWNLOAD_DIR}/${SOFTWARE} ]; then
        print_colored "$BLUE" "File ${SOFTWARE} already exists"
    else
        print_colored "$BLUE" "Downloading ${SOFTWARE}..."
        wget -O ${DOWNLOAD_DIR}/${SOFTWARE} ${URL}
    fi
}

function unpack_node_exporter() {
    if [ -d ${BASE_DIR} ]; then
        print_colored "$BLUE" "Directory ${BASE_DIR} already exists"
    else
        print_colored "$BLUE" "Unpacking ${SOFTWARE}..."
        cd ${DOWNLOAD_DIR} || exit
        tar xvf ${DOWNLOAD_DIR}/${SOFTWARE}
    fi
}

function configure_node_exporter() {
    ln -s node_exporter-${VERSION}.linux-${ARCH} ${BASE_DIR}
    chown -R node_exporter:node_exporter ${BASE_DIR}/
    chmod -R 755 ${BASE_DIR}
}

function install_node_exporter() {
  print_colored "$BLUE" "Installing node_exporter..."
}

function create_service() {
  cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
Restart=on-failure
ExecStart=${BASE_DIR}/node_exporter

[Install]
WantedBy=multi-user.target
EOF
}

function start_node_exporter() {
  systemctl daemon-reload
  systemctl enable node_exporter
  systemctl start node_exporter
  systemctl status node_exporter
}

function main() {
  check_root
  create_user
  download_node_exporter
  unpack_node_exporter
  configure_node_exporter
  install_node_exporter
  create_service
  start_node_exporter
}

main



