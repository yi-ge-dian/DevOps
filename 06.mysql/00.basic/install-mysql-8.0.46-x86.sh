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

IP=$1
groupIP_1=$2
groupIP_2=$3
if [[ -z "$IP" || -z "$groupIP_1" || -z "$groupIP_2" ]]; then
    print_colored "$RED" "[Error] Usage: $0 <IP_ADDRESS> <GROUP_IP_1> <GROUP_IP_2>"
    exit 1
fi

# 获取ip地址最后一个段
ip_end=$(echo $IP | awk -F. '{print $NF}') 
echo "ip_end: $ip_end"

Port="3306"
MGR_Port="33306"
ServerId="$ip_end$Port"

# 检查是否含有 mariaDB
rpm -qa | grep mariadb
if [[ $? -eq 0 ]]; then
    print_colored "$YELLOW" "[Warning] MariaDB is installed, uninstalling..."
    yum remove -y mariadb*
fi

# 二进制安装
cd /usr/local || exit
if [[ -f mysql-8.0.46-linux-glibc2.17-$arch.tar.xz ]]; then
    print_colored "$GREEN" "[Success] MySQL is downloaded!"
else
    print_colored "$GREEN" "[Success] Downloading MySQL..."
    wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.46-linux-glibc2.17-$arch.tar.xz
    print_colored "$GREEN" "[Success] Downloading completed!"
fi

# 解压
tar xvf mysql-8.0.46-linux-glibc2.17-$arch.tar.xz
ln -s mysql-8.0.46-linux-glibc2.17-$arch mysql

# 配置环境变量
cat >> /etc/profile << 'EOF'
export PATH=/usr/local/mysql/bin:$PATH
EOF
source /etc/profile
mysql -V

# 创建数据目录
useradd -r -s /sbin/nologin mysql
mkdir -pv /data/$Port/{data,log,run,etc,backup}
mkdir -pv /data/$Port/log/{binlog,relaylog}
touch /data/$Port/etc/my.cnf
chown -R mysql.mysql /data/$Port/
chown -R mysql.mysql /usr/local/mysql/
chmod 700 /data/$Port

# 初始化数据库
mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/$Port/data

# 配置服务
cat > /data/$Port/etc/my.cnf << EOF
[mysql]
port = $Port
socket = /data/$Port/run/mysql.sock
default-character-set = utf8mb4

[mysqld]
#------------------------------------------------------------
#basic configuration
#------------------------------------------------------------
server-id = $ServerId
port = $Port
user = mysql
bind-address = $IP
basedir = /usr/local/mysql
datadir = /data/$Port/data
pid-file = /data/$Port/run/mysqld.pid
socket = /data/$Port/run/mysql.sock
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 500
skip_name_resolve = on

#------------------------------------------------------------
#general_log and error_log
#------------------------------------------------------------
general_log = off
general_log_file = /data/$Port/log/general.log
log_error = /data/$Port/log/error.log

#------------------------------------------------------------
#binlog
#------------------------------------------------------------
log_bin = /data/$Port/log/binlog/mysql-binlog
log_bin_index = /data/$Port/log/binlog/mysql-binlog.index
binlog_format = row
binlog_rows_query_log_events = on
binlog_expire_logs_seconds = 2592000
binlog_cache_size = 1M
max_binlog_size = 1024M

#------------------------------------------------------------
#slowlog
#------------------------------------------------------------
slow_query_log = 1
slow_query_log_file = /data/$Port/log/slow.log
long_query_time = 3
log_queries_not_using_indexes = 0

#------------------------------------------------------------
#transaction
#------------------------------------------------------------ 
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1
transaction-isolation = read-committed
gtid_mode = on 
enforce_gtid_consistency = on
binlog_gtid_simple_recovery = on

#------------------------------------------------------------
#security
#------------------------------------------------------------ 
activate_all_roles_on_login = on

#------------------------------------------------------------
#slave parameters
#------------------------------------------------------------
#relay_log = /data/$Port/log/relaylog/mysql-relaylog
#relay_log_index = /data/$Port/log/relaylog/mysql-relaylog.index
#log_replica_updates = on
#read_only = on
#super_read_only = on
#replica-parallel-workers = 4
#relay_log_recovery = 1
#replica_skip_errors = ddl_exist_errors
#replica_preserve_commit_order = 1

#------------------------------------------------------------
#lossless semi-synchronous parameters
#------------------------------------------------------------
#plugin_dir = /usr/local/mysql/lib/plugin
#loose-plugin_load_add = "rpl_semi_sync_source=semisync_source.so"
#loose-plugin_load_add = "rpl_semi_sync_replica=semisync_replica.so"
#loose-rpl_semi_sync_source_enabled = 1
#loose-rpl_semi_sync_replica_enabled = 1
#loose-rpl_semi_sync_source_timeout = 5000
#loose-rpl_semi_sync_source_wait_point = AFTER_SYNC
#loose-rpl_semi_sync_source_wait_for_replica_count = 1

#------------------------------------------------------------
#mgr parameters
#------------------------------------------------------------
#plugin_dir = /usr/local/mysql/lib/plugin
#relay_log = /data/$Port/log/relaylog/mysql-relaylog
#relay_log_index = /data/$Port/log/relaylog/mysql-relaylog.index
#log_replica_updates = on
#loose-group_replication_local_address = "$IP:$MGR_Port"
#loose-plugin_load_add = "mysql_clone.so"
#loose-plugin_load_add = "group_replication.so"
#loose-group_replication_group_name = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"
#loose-group_replication_group_seeds = "$IP:$MGR_Port,$groupIP_1:$MGR_Port,$groupIP_2:$MGR_Port"
#loose-group_replication_start_on_boot = on
#loose-group_replication_bootstrap_group = off
#loose-group_replication_exit_state_action = READ_ONLY
#loose-group_replication_flow_control_mode = "DISABLED"
#loose-group_replication_single_primary_mode = on
#loose-group_replication_recovery_get_public_key = on
#report-host = $IP
EOF

# 启动服务
cat >/usr/lib/systemd/system/mysqld$Port.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql
LimitNOFILE=65535
LimitNPROC=65535
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/$Port/etc/my.cnf
EOF

systemctl daemon-reload
systemctl start mysqld$Port
if [[ $? -eq 0 ]]; then
    print_colored "$GREEN" "[Success] MySQL is running!"
else
    print_colored "$RED" "[Error] MySQL running error!"
    exit 1
fi

systemctl enable mysqld$Port
if [[ $? -eq 0 ]]; then
    print_colored "$GREEN" "[Success] MySQL is enabled!"
else
    print_colored "$RED" "[Error] MySQL enable error!"
    exit 1
fi
systemctl status mysqld$Port

cat >> /etc/profile << EOF
alias mysql="mysql --defaults-file=/data/$Port/etc/my.cnf"
alias mysqladmin="mysqladmin -S /data/3306/run/mysql.sock"
EOF

#source /etc/profile
#mysqladmin -uroot password '123456'
#CREATE USER 'root'@'%' IDENTIFIED BY '123456';
#GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
#flush privileges;
#SELECT user,host,plugin FROM mysql.user;
