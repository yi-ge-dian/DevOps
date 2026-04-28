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

# 设置 scp 机器 IP
SCP_MANCHINE_IP="xxx.xxx.xxx.xxx"

# 查看 scp 机器是否可达
if ! ping -c 1 -W 1 "$SCP_MANCHINE_IP" &>/dev/null; then
    print_colored "$RED" "[Error] IP $SCP_MANCHINE_IP is not reachable"
    exit 1
fi

# 创建备份目录
back_dir="backup-$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p /data/pritunl/$back_dir

# 开始备份
cp -a /data/pritunl/pritunl /data/pritunl/$back_dir
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to copy pritunl directory"
    exit 1
fi
cp -a /data/pritunl/mongodb /data/pritunl/$back_dir
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to copy mongodb directory"
    exit 1
fi
print_colored "$GREEN" "[Success] Backup copied to /data/pritunl/$back_dir"

# 压缩备份
cd /data/pritunl
tar -zcf $back_dir.tar.gz -C /data/pritunl/$back_dir/ .
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to compress backup"
    exit 1
fi
print_colored "$GREEN" "[Success] Backup compressed to $back_dir.tar.gz"

# 发送备份到远程机器
scp $back_dir.tar.gz root@$SCP_MANCHINE_IP:/data/pritunl/backup/
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to send backup to remote machine"
    exit 1
fi

# 设置定时任务
# crontab -e
# 0 22 * * 5 /root/dongwenlong/pritunl-backup.sh >> /var/log/pritunl_backup.log 2>&1
# chmod +x /root/dongwenlong/pritunl-backup.sh

# 恢复
# cd /data/pritunl/backup/
# tar xvf xxx.tar.gz -C .
# mv pritunl ../
# mv mongodb ../
# docker-compose up -d