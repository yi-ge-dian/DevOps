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

VERSION=13.0.2
ARCH=amd64
SOFTWARE=grafana-enterprise_${VERSION}_26816849631_linux_${ARCH}.tar.gz
URL=https://dl.grafana.com/grafana-enterprise/release/${VERSION}/${SOFTWARE}
DOWNLOAD_DIR=/usr/local
BASE_DIR=/usr/local/grafana
DATA_DIR=/data/grafana/data
LOG_DIR=/data/grafana/log
ETC_DIR=/data/grafana/etc
BACKUP_DIR=/data/grafana/backup
RUN_DIR=/data/grafana/run


function create_user(){
      if id grafana &>/dev/null; then
        print_colored "$BLUE" "User grafana already exists"
    else
        print_colored "$BLUE" "Creating user grafana..."
        useradd -r -s /sbin/nologin grafana
    fi
}

function download_grafana() {
    if [ -f ${DOWNLOAD_DIR}/${SOFTWARE} ]; then
        print_colored "$BLUE" "File ${SOFTWARE} already exists"
    else
        print_colored "$BLUE" "Downloading ${SOFTWARE}..."
        wget -O ${DOWNLOAD_DIR}/${SOFTWARE} ${URL}
    fi
}

function unpack_grafana() {
    if [ -d ${BASE_DIR} ]; then
        print_colored "$BLUE" "Directory ${BASE_DIR} already exists"
    else
        print_colored "$BLUE" "Unpacking ${SOFTWARE}..."
        cd ${DOWNLOAD_DIR} || exit
        tar -xvf ${DOWNLOAD_DIR}/${SOFTWARE}
    fi
    ln -s grafana-${VERSION} ${BASE_DIR}
    chown -R grafana:grafana ${BASE_DIR}/
    chmod -R 755 ${BASE_DIR}
}

function configure_grafana() {
    mkdir -p ${DATA_DIR} ${LOG_DIR} ${ETC_DIR} ${BACKUP_DIR} ${RUN_DIR}
    chown -R grafana:grafana ${DATA_DIR} ${LOG_DIR} ${ETC_DIR} ${BACKUP_DIR} ${RUN_DIR}
    chmod -R 755 ${DATA_DIR} ${LOG_DIR} ${ETC_DIR} ${BACKUP_DIR} ${RUN_DIR}
    cp -a ${BASE_DIR}/conf/defaults.ini ${ETC_DIR}/grafana.ini

    sed -i "s#data = data#data = ${DATA_DIR}#g" ${ETC_DIR}/grafana.ini
    sed -i "s#logs = data/log#logs = ${LOG_DIR}#g" ${ETC_DIR}/grafana.ini
}

function install_grafana() {
    print_colored "$BLUE" "Installing Grafana..."
}

function create_service() {
  cat > /etc/systemd/system/grafana.service << EOF
[Unit]
Description=Grafana
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=grafana
Group=grafana
Restart=on-failure
ExecStart=${BASE_DIR}/bin/grafana server --homepath=${BASE_DIR} --config=${ETC_DIR}/grafana.ini

[Install]
WantedBy=multi-user.target
EOF
}

function start_grafana() {
    systemctl daemon-reload
    systemctl enable grafana
    systemctl start grafana
    systemctl status grafana
}

function main() {
    check_root
    create_user
    download_grafana
    unpack_grafana
    configure_grafana
    install_grafana
    create_service
    start_grafana
}
main