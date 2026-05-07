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

Redis_version="7.4.8"

# 优化系统参数
cat > /etc/sysctl.conf << EOF
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 4096
vm.overcommit_memory = 1
EOF
sysctl -p
print_colored "$GREEN" "[Success] Redis perf configured"

# 设置透明大页
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
print_colored "$GREEN" "[Success] Transparent_hugepage set"

# 判断是否下载了源码包
cd /usr/local/src
if [[ -f "redis-${Redis_version}.tar.gz" ]]; then
    print_colored "$GREEN" "[Success] Redis tar already exists"
else
    print_colored "$BLUE" "[Info] Downloading Redis v${Redis_version}"
    wget https://download.redis.io/releases/redis-${Redis_version}.tar.gz
    if [[ $? -ne 0 ]]; then
        print_colored "$RED" "[Error] Failed to download Redis"
        exit 1
    fi
    print_colored "$GREEN" "[Success] Redis tar downloaded"
fi

# 安装 redis
tar xvf redis-${Redis_version}.tar.gz
cd /usr/local/src/redis-${Redis_version}
make -j "$(nproc)" USE_SYSTEMD=yes
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to make Redis"
    exit 1
fi
print_colored "$GREEN" "[Success] Redis made"

make install PREFIX=/usr/local/redis
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to install Redis"
    exit 1
fi
print_colored "$GREEN" "[Success] Redis installed"

# 查看 redis 版本
cd /usr/local/redis/bin
redis-server -v

# 配置环境变量
cat >> /etc/profile << EOF
export PATH=/usr/local/redis/bin:$PATH
EOF
source /etc/profile

# 配置目录
mkdir -pv /data/6379/{data,etc,log,run,backup}
cp -a /usr/local/src/redis-${Redis_version}/redis.conf /data/6379/etc/redis.conf
useradd -r -s /sbin/nologin redis
chown -R redis.redis /data/6379/
chown -R redis.redis /usr/local/redis/
chmod 700 /data/6379

# 配置文件
cat >> /data/6379/etc/redis.conf << EOF
####################################### basic configuration
bind 0.0.0.0
port 6379
unixsocket /data/6379/run/redis.sock
supervised systemd
dir /data/6379/data
pidfile /data/6379/run/redis.pid
logfile "/data/6379/log/redis.log"
####################################### slow log configuration
slowlog-log-slower-than 100000
slowlog-max-len 128
####################################### connection configuration
maxclients 10000
requirepass 123456
maxmemory 16gb
######################################## persistence configuration
appendonly yes
appendfilename "appendonly-6379.aof"
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 1024MB
####################################### safe configuration
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""
rename-command SHUTDOWN ""
rename-command KEYS ""
EOF
print_colored "$GREEN" "[Success] Redis conf configured"

# 配置 systemd
cat > /usr/lib/systemd/system/redis6379.service << EOF
[Unit]
Description=Redis Server
After=network.target

[Service]
ExecStart=/usr/local/redis/bin/redis-server /data/6379/etc/redis.conf
Type=notify
User=redis
Group=redis
LimitNOFILE=65535
LimitNPROC=65535
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
print_colored "$GREEN" "[Success] Redis systemd service configured"

# 启动 redis
systemctl daemon-reload
systemctl start redis6379
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to start Redis service"
    exit 1
fi
systemctl enable redis6379
if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to enable Redis service"
    exit 1
fi
print_colored "$GREEN" "[Success] Redis service started and enabled on boot"

# 查看 redis 状态
systemctl status redis6379