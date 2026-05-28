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

# 校验是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   print_colored "$RED" "[Error] This script must be run as root"
   exit 1
fi

# 获得 CPU 架构
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
    print_colored "$GREEN" "[Success] Machine architecture: x86_64"
elif [[ "$arch" == "aarch64" ]]; then
    print_colored "$GREEN" "[Success] Machine architecture: aarch64"
else
    print_colored "$RED" "[Error] Unsupported machine architecture: $arch"
    exit 1
fi

version="22.10.1.1877"
cd /usr/local || exit

# 安装 clickhouse-common-static
if [[ -f clickhouse-common-static-$version-amd64.tgz ]]; then
    print_colored "$GREEN" "[Success] clickhouse-common-static is downloaded!"
else
    print_colored "$GREEN" "[Success] Downloading clickhouse-common-static..."
    wget https://packages.clickhouse.com/tgz/stable/clickhouse-common-static-$version-amd64.tgz
    print_colored "$GREEN" "[Success] Downloading completed!"
fi

if [[ -d clickhouse-common-static-$version ]] ; then
    print_colored "$GREEN" "[Success] clickhouse-common-static is uncompressed!"
else
    print_colored "$GREEN" "[Success] Installing clickhouse-common-static..."
    tar xvf clickhouse-common-static-$version-amd64.tgz
    print_colored "$GREEN" "[Success] clickhouse-common-static uncompressed successfully!"
fi

./clickhouse-common-static-$version/install/doinst.sh
if [ $? -ne 0 ]; then
  print_colored "$RED" "[Error] clickhouse-common-static installation failed!"
  exit 1
fi

# 安装 clickhouse-common-static-dbg
if [[ -f clickhouse-common-static-dbg-$version-amd64.tgz ]]; then
    print_colored "$GREEN" "[Success] clickhouse-common-static-dbg is downloaded!"
else
    print_colored "$GREEN" "[Success] Downloading clickhouse-common-static-dbg..."
    wget https://packages.clickhouse.com/tgz/stable/clickhouse-common-static-dbg-$version-amd64.tgz
    print_colored "$GREEN" "[Success] Downloading completed!"
fi

if [[ -d clickhouse-common-static-dbg-$version ]] ; then
    print_colored "$GREEN" "[Success] clickhouse-common-static-dbg is uncompressed!"
else
    print_colored "$GREEN" "[Success] Installing clickhouse-common-static-dbg..."
    tar xvf clickhouse-common-static-dbg-$version-amd64.tgz
    print_colored "$GREEN" "[Success] clickhouse-common-static-dbg uncompressed successfully!"
fi

./clickhouse-common-static-dbg-$version/install/doinst.sh
if [ $? -ne 0 ]; then
  print_colored "$RED" "[Error] clickhouse-common-static-dbg installation failed!"
  exit 1
fi

# 安装 clickhouse-server
if [[ -f clickhouse-server-$version-amd64.tgz ]]; then
    print_colored "$GREEN" "[Success] clickhouse-server is downloaded!"
else
    print_colored "$GREEN" "[Success] Downloading clickhouse-server..."
    wget https://packages.clickhouse.com/tgz/stable/clickhouse-server-$version-amd64.tgz
    print_colored "$GREEN" "[Success] Downloading completed!"
fi

if [[ -d clickhouse-server-$version ]] ; then
    print_colored "$GREEN" "[Success] clickhouse-server is uncompressed!"
else
    print_colored "$GREEN" "[Success] Installing clickhouse-server..."
    tar xvf clickhouse-server-$version-amd64.tgz
    print_colored "$GREEN" "[Success] clickhouse-server uncompressed successfully!"
fi

mkdir -pv /data/clickhouse/{data,log,etc,backup}
useradd -r -s /sbin/nologin clickhouse
chown -R clickhouse:clickhouse /data/clickhouse
chmod -R 755 /data/clickhouse

CLICKHOUSE_INSTALL_FILE="/usr/local/clickhouse-server-$version/install/doinst.sh"
sed -i "s#/var/lib/clickhouse#/data/clickhouse/data#g" "$CLICKHOUSE_INSTALL_FILE"
sed -i "s#/var/log/clickhouse-server#/data/clickhouse/log#g" "$CLICKHOUSE_INSTALL_FILE"

# 修改配置中的路径，将默认路径替换为自定义数据目录
CONFIG_FILE="/usr/local/clickhouse-server-$version/etc/clickhouse-server/config.xml"
sed -i "s#<log>/var/log/clickhouse-server#<log>/data/clickhouse/log#g" "$CONFIG_FILE"
sed -i "s#<errorlog>/var/log/clickhouse-server#<errorlog>/data/clickhouse/log#g" "$CONFIG_FILE"
sed -i "s#<\!-- <listen_host>::</listen_host> -->#<listen_host>::</listen_host>#g" "$CONFIG_FILE"
sed -i "s#<path>/var/lib/clickhouse#<path>/data/clickhouse/data#g" "$CONFIG_FILE"
sed -i "s#<tmp_path>/var/lib/clickhouse#<tmp_path>/data/clickhouse/data#g" "$CONFIG_FILE"
sed -i "s#<user_files_path>/var/lib/clickhouse#<user_files_path>/data/clickhouse/data#g" "$CONFIG_FILE"
sed -i "s#<format_schema_path>/var/lib/clickhouse#<format_schema_path>/data/clickhouse/data#g" "$CONFIG_FILE"

USER_FILE="/usr/local/clickhouse-server-$version/etc/clickhouse-server/users.xml"
sed -i "s@<\!-- <access_management>1</access_management> -->@<access_management>1</access_management>@g" "$USER_FILE"
./clickhouse-server-$version/install/doinst.sh

# 安装 clickhouse-client
if [[ -f clickhouse-client-$version-amd64.tgz ]]; then
    print_colored "$GREEN" "[Success] clickhouse-client is downloaded!"
else
    print_colored "$GREEN" "[Success] Downloading clickhouse-client..."
    wget https://packages.clickhouse.com/tgz/stable/clickhouse-client-$version-amd64.tgz
    print_colored "$GREEN" "[Success] Downloading completed!"
fi

if [[ -d clickhouse-client-$version ]] ; then
    print_colored "$GREEN" "[Success] clickhouse-client is uncompressed!"
else
    print_colored "$GREEN" "[Success] Installing clickhouse-client..."
    tar xvf clickhouse-client-$version-amd64.tgz
    print_colored "$GREEN" "[Success] clickhouse-client uncompressed successfully!"
fi

./clickhouse-client-$version/install/doinst.sh
if [ $? -ne 0 ]; then
  print_colored "$RED" "[Error] clickhouse-server installation failed!"
  exit 1
fi

mv /etc/clickhouse* /data/clickhouse/etc
ln -s /data/clickhouse/etc/* /etc/
chown -R clickhouse:clickhouse /data/clickhouse
chmod -R 755 /data/clickhouse

systemctl enable clickhouse-server --now
systemctl status clickhouse-server
if [ $? -ne 0 ]; then
  print_colored "$RED" "[Error] clickhouse-server start failed!"
  exit 1
fi