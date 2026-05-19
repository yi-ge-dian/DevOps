cd /usr/local/src
wget https://ftp.postgresql.org/pub/source/v15.5/postgresql-15.5.tar.gz
tar -xzf postgresql-15.5.tar.gz
cd postgresql-15.5

yum install -y readline-devel zlib-devel openssl-devel libxml2-devel libxslt-devel perl-devel perl-ExtUtils-Embed python3-devel systemd-devel lz4-devel libzstd-devel libuuid-devel libicu-devel

./configure --prefix=/usr/local/pgsql \
            --with-pgport=5432 \
            --with-openssl \
            --with-perl --with-python --with-libxml --with-libxslt   \
            --with-systemd \
            --with-lz4 --with-zstd --with-uuid=e2fs --with-icu --enable-thread-safety
make -j $(nproc)
make install

useradd -s /bin/bash -r -m -d /home/postgres postgres
echo postgres:wzdmzl@666 | chpasswd


cat >> /etc/profile << EOF
export PGHOME=/usr/local/pgsql
export PGHOST=/data/5432/run
export PGPORT=5432
export PGDATA=/data/5432/data
export PGUSER=postgres
export PATH=\$PGHOME/bin:\$PATH
EOF
source /etc/profile

mkdir -pv /data/5432/{archive,backup,data,log,run}
chown -R postgres.postgres /usr/local/pgsql/
chown -R postgres.postgres /data/5432/
chmod -R 700 /data/5432/


sudo -iu postgres initdb -D /data/5432/data -U postgres -E UTF8 --locale=zh_CN.UTF-8


cp -a /data/5432/data/pg_hba.conf /data/5432/data/pg_hba.conf.bak
cp -a /data/5432/data/postgresql.conf /data/5432/data/postgresql.conf.bak

# 通过 postgresql.conf 文件，可以调整 PostgreSQL 的性能，以适应您的系统资源和工作负载要求

# 1. shared_buffers should be set to 25% of total system memory
total_memory=$(free -g | awk '/^Mem:/{print $2}')
calculated_shared_buffers=$(( (total_memory + 3) / 4 ))
# set shared_buffers to the calculated value, but not less than 1GB
if [[ $calculated_shared_buffers -lt 1 ]]; then
    shared_buffers=1
else
    shared_buffers=$calculated_shared_buffers
fi

echo "Calculated shared_buffers: ${shared_buffers}GB"

cat >> /data/5432/data/postgresql.conf << EOF
external_pid_file = '/data/5432/run/postmaster.pid'
listen_addresses= '*'
port = 5432
max_connections = 500
unix_socket_directories = '/data/5432/run'
shared_buffers = ${shared_buffers}GB 
logging_collector=on
log_directory='/data/5432/log'
log_filename = 'postgresql-%a.log'
log_rotation_age = 1d
log_rotation_size = 1GB
log_truncate_on_rotation = on
log_min_duration_statement = 5000
idle_in_transaction_session_timeout = 1000000
idle_session_timeout = 300000
wal_level = replica
max_wal_senders = 10
wal_sender_timeout = 60s
wal_log_hints = on
archive_mode = on
archive_command = 'test ! -f /data/5432/archive/%f && cp %p /data/5432/archive/%f'
EOF


cat > /usr/lib/systemd/system/postgresql5432.service << EOF
# It's not recommended to modify this file in-place, because it will be
# overwritten during package upgrades.  It is recommended to use systemd
# "dropin" feature;  i.e. create file with suffix .conf under
# /etc/systemd/system/postgresql-15.service.d directory overriding the
# unit's defaults. You can also use "systemctl edit postgresql-15"
# Look at systemd.unit(5) manual page for more info.

# Note: changing PGDATA will typically require adjusting SELinux
# configuration as well.

# Note: do not use a PGDATA pathname containing spaces, or you will
# break postgresql-15-setup.
[Unit]
Description=PostgreSQL 15 database server
Documentation=https://www.postgresql.org/docs/15/static/
After=syslog.target
After=network-online.target

[Service]
Type=notify

User=postgres
Group=postgres

# Note: avoid inserting whitespace in these Environment= lines, or you may
# break postgresql-setup.

# Location of database directory
Environment=PGDATA=/data/5432/data/

# Where to send early-startup messages from the server (before the logging
# options of postgresql.conf take effect)
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000
Environment=PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
Environment=PG_OOM_ADJUST_VALUE=0

ExecStart=/usr/local/pgsql/bin/postmaster -D ${PGDATA}
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGINT
 
# Do not set any timeout value, so that systemd will not kill postmaster
# during crash recovery.
TimeoutSec=0

# 0 is the same as infinity, but "infinity" needs systemd 229
TimeoutStartSec=0

TimeoutStopSec=1h

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable postgresql5432 --now
if systemctl is-active --quiet postgresql5432; then
    print_colored "$GREEN" "PostgreSQL service started successfully"
    systemctl status postgresql5432 --no-pager
else
    print_colored "$RED" "Failed to start PostgreSQL service"
    exit 1
fi

# e.g.create user
# 创建 my_user 用户，并设置密码为 123456，user 默认具有登录权限
# CREATE USER my_user WITH PASSWORD '123456';

# 创建 my_role 角色，并设置密码为 123456，role 默认不具有登录权限,如果想要登录权限，请使用 WITH LOGIN
# CREATE ROLE my_role WITH LOGIN PASSWORD '123456';

# 创建 my_database 数据库，所有者为 my_user 用户
# CREATE DATABASE my_database OWNER my_user;

# 创建 my_database 数据库，所有者为 my_role 角色
# CREATE DATABASE my_database OWNER my_role;

# 删除 my_database 数据库
# DROP DATABASE my_database;

# 删除 my_user 用户
# DROP USER my_user;

