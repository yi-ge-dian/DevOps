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

VERSION=3.5.3
ARCH=amd64
SOFTWARE=prometheus-${VERSION}.linux-${ARCH}.tar.gz
URL=https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${SOFTWARE}
DOWNLOAD_DIR=/usr/local
BASE_DIR=/usr/local/prometheus
DATA_DIR=/data/prometheus/data
LOG_DIR=/data/prometheus/log
ETC_DIR=/data/prometheus/etc

function create_user() {
    if id prometheus &>/dev/null; then
        print_colored "$BLUE" "User prometheus already exists"
    else
        print_colored "$BLUE" "Creating user prometheus..."
        useradd -r -s /sbin/nologin prometheus
    fi
}

function download_prometheus() {
    if [ ! -f ${DOWNLOAD_DIR}/${SOFTWARE} ]; then
        print_colored "$BLUE" "Downloading prometheus..."
        wget -O ${DOWNLOAD_DIR}/${SOFTWARE} ${URL}
    fi
}

function unpack_prometheus() {
    cd ${DOWNLOAD_DIR} || exit 1
    print_colored "$BLUE" "Unpacking prometheus..."
    tar xvf ${DOWNLOAD_DIR}/${SOFTWARE}
    ln -s prometheus-${VERSION}.linux-${ARCH} ${BASE_DIR}
    chown -R prometheus:prometheus ${BASE_DIR}/
    chmod -R 755 ${BASE_DIR}
}

function install_prometheus() {
    print_colored "$BLUE" "Installing prometheus..."
    mkdir -p ${DATA_DIR} ${LOG_DIR} ${ETC_DIR}
    chown -R prometheus:prometheus ${DATA_DIR} ${LOG_DIR} ${ETC_DIR}
    chmod -R 755 ${DATA_DIR} ${LOG_DIR} ${ETC_DIR}
    cp -a ${BASE_DIR}/prometheus.yml ${ETC_DIR}/
    mv ${BASE_DIR}/prometheus.yml ${BASE_DIR}/prometheus.yml.bak
}

function create_service() {
    print_colored "$BLUE" "Creating service..."
    cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
Restart=on-failure
ExecStart=${BASE_DIR}/prometheus \
--config.file=${ETC_DIR}/prometheus.yml \
--storage.tsdb.path=${DATA_DIR} \
--storage.tsdb.retention.time=15d \
--web.enable-lifecycle
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
}

function start_service() {
    print_colored "$BLUE" "Starting service..."
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
    systemctl status prometheus
}

function main() {
  check_root
  create_user
  download_prometheus
  unpack_prometheus
  install_prometheus
  create_service
  start_service
  print_colored "$GREEN" "Prometheus installed successfully!"
}