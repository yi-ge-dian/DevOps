# 在线
yum install -y vim wget net-tools lsof iotop chrony unzip tree gcc make perl gcc-c++ cmake tar
yum install -y readline-devel zlib-devel openssl-devel libxml2-devel libxslt-devel perl-devel perl-ExtUtils-Embed python3-devel systemd-devel lz4-devel libzstd-devel libuuid-devel libicu-devel bison flex


# 离线
mkdir -pv offline-packages
yum install -y --downloadonly --downloaddir=./offline-packages \
    vim wget net-tools lsof iotop chrony unzip tree gcc make perl gcc-c++ cmake tar\
    readline-devel \
    zlib-devel \
    openssl-devel \
    libxml2-devel \
    libxslt-devel \
    perl-devel \
    perl-ExtUtils-Embed \
    python3-devel \
    systemd-devel \
    lz4-devel \
    libzstd-devel \
    libuuid-devel \
    libicu-devel \
    bison \
    flex \

cd /usr/local/src
wget https://ftp.postgresql.org/pub/source/v18.4/postgresql-18.4.tar.gz
tar -xvzf postgresql-18.4.tar.gz
cd postgresql-18.4
./configure --prefix=/usr/local/pgsql \
            --with-pgport=5432 \
            --with-openssl \
            --with-perl --with-python --with-libxml --with-libxslt \
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
chmod -R 755 /usr/local/pgsql/
chown -R postgres.postgres /data/5432/
chmod -R 755 /data/5432/


sudo -iu postgres initdb -D /data/5432/data -U postgres -E UTF8
ll /data/5432/data

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
wal_keep_size = 2GB
max_wal_size = 4GB
min_wal_size = 1GB
EOF

cat >/etc/systemd/system/postgresql5432.service<<'EOF'
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking
User=postgres
Group=postgres
Environment=PGPORT=5432
Environment=PGDATA=/data/5432/data
OOMScoreAdjust=-1000
ExecStart=/usr/local/pgsql/bin/pg_ctl  start  -D ${PGDATA} -s -o "-p ${PGPORT}" -w -t 300
ExecStop=/usr/local/pgsql/bin/pg_ctl   stop   -D ${PGDATA} -s -m fast
ExecReload=/usr/local/pgsql/bin/pg_ctl reload -D ${PGDATA} -s
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable postgresql5432 --now
systemctl status postgresql5432

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

