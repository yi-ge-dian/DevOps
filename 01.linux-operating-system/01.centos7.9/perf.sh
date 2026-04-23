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

# 优化系统参数
BACKUP_FILE="/etc/sysctl.conf.backup_$(date +%Y%m%d_%H%M%S)"
cp -a /etc/sysctl.conf "$BACKUP_FILE"
cat >> /etc/sysctl.conf << EOF
################################################################  Memory Optimization ################################################################
# 设置系统内存中脏页的最大比例和最小比例，优化磁盘写入性能，若是写入密集型应用，建议调小，若是低时延型应用，建议调大
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
# 减少系统使用交换分区的倾向
vm.swappiness = 5
###############################################################  Network Optimization ################################################################
# ARP/邻居表缓存大小优化 (适用于高并发/容器环境)
net.ipv4.neigh.default.gc_thresh1 = 8192
net.ipv4.neigh.default.gc_thresh2 = 32768
net.ipv4.neigh.default.gc_thresh3 = 65536
EOF
sysctl -p
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to optimize system settings"
    exit 1
else
    print_colored "$GREEN" "[Success] System settings optimized, backup created at $BACKUP_FILE"
fi

