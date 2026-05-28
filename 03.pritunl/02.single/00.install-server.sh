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

# 加载 pritunl 镜像
pritunl_tar_path="/root/dongwenlong/pritunl.tar"
docker load -i $pritunl_tar_path
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to load Docker images from pritunl tar"
    exit 1
fi

# 创建 docker-compose.yaml 文件
mkdir -p /data/pritunl
cat > /data/pritunl/docker-compose.yaml << EOF
version: '3.3'
services:
    pritunl:
        container_name: pritunl
        image: jippi/pritunl:1.32.3697.80 
        restart: unless-stopped
        privileged: true
        ports:
            - '8443:443'
            - '1195:1195'
            - '1195:1195/udp'
            - '1196:1196'
            - '1196:1196/udp'
        dns:
            - 127.0.0.1
        volumes:
            - '/data/pritunl/pritunl:/var/lib/pritunl'
            - '/data/pritunl/mongodb:/var/lib/mongodb'
            - '/etc/localtime:/etc/localtime:ro'
EOF
print_colored "$GREEN" "[Success] Docker images loaded and docker-compose.yaml created"

# 启动 pritunl 容器
cd /data/pritunl
docker-compose up -d
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to start the pritunl container"
    exit 1
fi
print_colored "$GREEN" "[Success] Pritunl container started"

# 获取 pritunl 默认密码
docker exec pritunl pritunl default-password
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to get the pritunl default password"
    exit 1
fi