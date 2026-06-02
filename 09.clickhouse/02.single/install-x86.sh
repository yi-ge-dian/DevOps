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

VERSION=22.10.1.1877
ARCH=amd64
SOFTWARE_COMMON=clickhouse-common-static-${VERSION}-${ARCH}.tgz
SOFTWARE_COMMON_DBG=clickhouse-common-static-dbg-${VERSION}-${ARCH}.tgz
SOFTWARE_SERVER=clickhouse-server-${VERSION}-${ARCH}.tgz
SOFTWARE_CLIENT=clickhouse-client-${VERSION}-${ARCH}.tgz
URL=https://packages.clickhouse.com/tgz/stable
DOWNLOAD_DIR=/usr/local
DATA_DIR=/data/clickhouse/data
LOG_DIR=/data/clickhouse/log
ETC_DIR=/data/clickhouse/etc
BACKUP_DIR=/data/clickhouse/backup


function create_user() {
    if id clickhouse &>/dev/null; then
        print_colored "$BLUE" "User clickhouse already exists"
    else
        print_colored "$BLUE" "Creating user clickhouse..."
        useradd -r -s /sbin/nologin clickhouse
    fi
}

function download_clickhouse(){
  if [ ! -f ${DOWNLOAD_DIR}/${SOFTWARE_COMMON} ]; then
    print_colored "$BLUE" "Downloading clickhouse-common-static..."
    wget -O ${DOWNLOAD_DIR}/${SOFTWARE_COMMON} ${URL}/${SOFTWARE_COMMON}
  fi

  if [ ! -f ${DOWNLOAD_DIR}/${SOFTWARE_COMMON_DBG} ]; then
    print_colored "$BLUE" "Downloading clickhouse-common-static-dbg..."
    wget -O ${DOWNLOAD_DIR}/${SOFTWARE_COMMON_DBG} ${URL}/${SOFTWARE_COMMON_DBG}
  fi

  if [ ! -f ${DOWNLOAD_DIR}/${SOFTWARE_SERVER} ]; then
    print_colored "$BLUE" "Downloading clickhouse-server..."
    wget -O ${DOWNLOAD_DIR}/${SOFTWARE_SERVER} ${URL}/${SOFTWARE_SERVER}
  fi

  if [ ! -f ${DOWNLOAD_DIR}/${SOFTWARE_CLIENT} ]; then
    print_colored "$BLUE" "Downloading clickhouse-client..."
    wget -O ${DOWNLOAD_DIR}/${SOFTWARE_CLIENT} ${URL}/${SOFTWARE_CLIENT}
  fi
}

function unpack_clickhouse() {
  if [ ! -d ${DOWNLOAD_DIR}/clickhouse-common-static-${VERSION} ]; then
    cd ${DOWNLOAD_DIR} || exit 1
    print_colored "$BLUE" "Unpacking clickhouse-common-static..."
    tar xvf ${DOWNLOAD_DIR}/${SOFTWARE_COMMON}
    chown -R clickhouse:clickhouse ${DOWNLOAD_DIR}/clickhouse-common-static-${VERSION}
    chmod -R 755 ${DOWNLOAD_DIR}/clickhouse-common-static-${VERSION}
  fi

  if [ ! -d ${DOWNLOAD_DIR}/clickhouse-common-static-dbg-${VERSION} ]; then
    cd ${DOWNLOAD_DIR} || exit 1
    print_colored "$BLUE" "Unpacking clickhouse-common-static-dbg..."
    tar xvf ${DOWNLOAD_DIR}/${SOFTWARE_COMMON_DBG}
    chown -R clickhouse:clickhouse ${DOWNLOAD_DIR}/clickhouse-common-static-dbg-${VERSION}
    chmod -R 755 ${DOWNLOAD_DIR}/clickhouse-common-static-dbg-${VERSION}
  fi


 if [ ! -d ${DOWNLOAD_DIR}/clickhouse-server-${VERSION} ]; then
    cd ${DOWNLOAD_DIR} || exit 1
    print_colored "$BLUE" "Unpacking clickhouse-server..."
    tar xvf ${DOWNLOAD_DIR}/${SOFTWARE_SERVER}
    chown -R clickhouse:clickhouse ${DOWNLOAD_DIR}/clickhouse-server-${VERSION}
    chmod -R 755 ${DOWNLOAD_DIR}/clickhouse-server-${VERSION}
  fi

    if [ ! -d ${DOWNLOAD_DIR}/clickhouse-client-${VERSION} ]; then
    cd ${DOWNLOAD_DIR} || exit 1
    print_colored "$BLUE" "Unpacking clickhouse-client..."
    tar xvf ${DOWNLOAD_DIR}/${SOFTWARE_CLIENT}
    chown -R clickhouse:clickhouse ${DOWNLOAD_DIR}/clickhouse-client-${VERSION}
    chmod -R 755 ${DOWNLOAD_DIR}/clickhouse-client-${VERSION}
  fi
}


function configure_clickhouse() {
    print_colored "$BLUE" "Configuring clickhouse..."
    mkdir -p ${DATA_DIR} ${LOG_DIR} ${ETC_DIR} ${BACKUP_DIR} ${RUN_DIR}
    chown -R clickhouse:clickhouse /data/clickhouse
    chmod -R 755 /data/clickhouse

    clickhouse_install_file="${DOWNLOAD_DIR}/clickhouse-server-${VERSION}/install/doinst.sh"
    sed -i "s#/var/lib/clickhouse#${DATA_DIR}#g" ${clickhouse_install_file}
    sed -i "s#/var/log/clickhouse-server#${LOG_DIR}#g" ${clickhouse_install_file}

    config_file="${DOWNLOAD_DIR}/clickhouse-server-${VERSION}/etc/clickhouse-server/config.xml"
    sed -i "s#<log>/var/log/clickhouse-server#<log>${LOG_DIR}#g" ${config_file}
    sed -i "s#<errorlog>/var/log/clickhouse-server#<errorlog>${LOG_DIR}#g" ${config_file}
    sed -i "s#<\!-- <listen_host>::</listen_host> -->#<listen_host>::</listen_host>#g" ${config_file}
    sed -i "s#<path>/var/lib/clickhouse#<path>$DATA_DIR#g" ${config_file}
    sed -i "s#<tmp_path>/var/lib/clickhouse#<tmp_path>${DATA_DIR}#g" ${config_file}
    sed -i "s#<user_files_path>/var/lib/clickhouse#<user_files_path>${DATA_DIR}#g" ${config_file}
    sed -i "s#<format_schema_path>/var/lib/clickhouse#<format_schema_path>${DATA_DIR}#g" ${config_file}

    users_file="${DOWNLOAD_DIR}/clickhouse-server-${VERSION}/etc/clickhouse-server/users.xml"
    sed -i "s@<\!-- <access_management>1</access_management> -->@<access_management>1</access_management>@g" ${users_file}
}

function install_clickhouse() {
  print_colored "$BLUE" "Installing clickhouse-common-static..."
  ${DOWNLOAD_DIR}/clickhouse-common-static-${VERSION}/install/doinst.sh
  print_colored "$BLUE" "Installing clickhouse-common-static-dbg..."
  ${DOWNLOAD_DIR}/clickhouse-common-static-dbg-${VERSION}/install/doinst.sh
  print_colored "$BLUE" "Installing clickhouse-server..."
  ${DOWNLOAD_DIR}/clickhouse-server-${VERSION}/install/doinst.sh
  print_colored "$BLUE" "Installing clickhouse-client..."
  ${DOWNLOAD_DIR}/clickhouse-client-${VERSION}/install/doinst.sh
}

function create_service() {
  print_colored "$BLUE" "Creating clickhouse service..."
  mv /etc/clickhouse* ${ETC_DIR}
  ln -sf ${ETC_DIR}/* /etc/
}

function start_clickhouse() {
  print_colored "$BLUE" "Starting clickhouse-server..."
  systemctl start clickhouse-server
  systemctl enable clickhouse-server
  systemctl status clickhouse-server
}

function main() {
  create_user
  download_clickhouse
  unpack_clickhouse
  configure_clickhouse
  install_clickhouse
  create_service
  start_clickhouse
  print_colored "$GREEN" "Clickhouse installed successfully"
}