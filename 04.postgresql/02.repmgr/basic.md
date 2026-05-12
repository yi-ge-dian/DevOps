1. 环境规划

- repmgr（监控复制过程、自动故障切换）
- witness（防止脑裂）
- keepalived（监控主库状态，自动切换VIP）

主库：10.0.0.61  + pg15.5 + postgis3.3 + repmgr5.4.1 [master]

备库：10.0.0.62  + pg15.5 + postgis3.3 + repmgr5.4.1 [slave]

仲裁：10.0.0.63  + pg15.5 + repmgr5.4.1 [witness]


2. 安装 repmgr

61 主节点执行

```shell
bash install-pg-15.5-x86.sh
source /etc/profile
bash install-postgis-3.3-x86.sh
bash install-repmgr-master-x86.sh 10.0.0.61 1 primary
```
62 备节点执行

```shell
bash install-pg-15.5-x86.sh
source /etc/profile
bash install-postgis-3.3-x86.sh
bash install-repmgr-slave-prepare-x86.sh 10.0.0.62 2
```

61 62 都执行

```shell
su postgres
cat > ~/.pgpass << EOF
10.0.0.61:5432:repmgr:repmgr:123456
10.0.0.61:5432:replication:repmgr:123456
10.0.0.62:5432:repmgr:repmgr:123456
10.0.0.62:5432:replication:repmgr:123456
EOF
cat ~/.pgpass
chmod 600 ~/.pgpass
exit
```

62 备节点执行

```shell
# 从 61 节点克隆数据
rm -rf /data/5432/data/*
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone --dry-run
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone

# 注册为备库
systemctl start postgresql5432
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby register --upstream-node-id=1
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf cluster show
```

3. 安装 witness

63 节点执行

```shell
bash install-pg-15.5-x86.sh
source /etc/profile
bash install-repmgr-witness-prepare-x86.sh 10.0.0.63 3

su postgres
echo "10.0.0.61:5432:repmgr:repmgr:123456" >> ~/.pgpass
echo "10.0.0.62:5432:repmgr:repmgr:123456" >> ~/.pgpass
echo "10.0.0.63:5432:repmgr:repmgr:123456" >> ~/.pgpass
chmod 600 ~/.pgpass
cat ~/.pgpass
exit
```

61 62执行

```shell
su postgres
echo "10.0.0.63:5432:repmgr:repmgr:123456" >> ~/.pgpass
cat ~/.pgpass
exit
```

63 节点执行

```shell
# 注册节点
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf -h 10.0.0.61 -U repmgr -d repmgr witness register
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf -U repmgr -d repmgr cluster show

# 查看节点信息
psql -d repmgr -c "select * from repmgr.nodes;"
```

61,62,63 配置 ssh 免密登录
```shell
echo 123456 | passwd --stdin postgres
su postgres
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.61
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.62
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.63
```

4. switchover 正常手动主从切换

62 节点执行

```shell
# 尝试切换
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind --dry-run

# 切换后，62 节点变为主库，61 节点变为备库
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind

# 62 建库建表，插入数据
createdb test
psql -d test -c "create table t1(id int);"
psql -d test -c "insert into t1 values(1);"
```

61 节点执行

```shell
# 查询数据
psql -d test -c "select * from t1;"
```

61 节点执行

```shell
# 尝试切换
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind --dry-run

# 切换后，61 节点变为主库，62 节点变为备库
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind

# 61 插入数据
psql -d test -c "insert into t1 values(2);"
```

62 节点执行

```shell
# 查询数据
psql -d test -c "select * from t1;"
```

5. failover 异常手动主从切换

61 节点执行

```shell
# 停止主库
systemctl stop postgresql5432
```

62 节点执行

```shell
# 提升为主库
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf --siblings-follow standby promote


# 插入数据
psql -d test -c "insert into t1 values(3);"
```

61 节点恢复
```shell
# 成为 62 的从库
sudo -iu postgres repmgr -h 10.0.0.62 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind --dry-run
sudo -iu postgres repmgr -h 10.0.0.62 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind

# 查询数据
psql -d test -c "select * from t1;"
```

将 61 节点恢复为主库，switchover 到 61 节点

```shell
# 61 尝试切换
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind --dry-run

# 切换后，61 节点变为主库，62 节点变为备库
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --force-rewind
```

6. failover 异常自动主从切换

```shell
# 1. 两台主从都启用 repmgr
echo "shared_preload_libraries = 'repmgr'" >> /data/5432/data/postgresql.conf
systemctl restart postgresql5432

# 2. 两台主从都修改配置
cat >> /data/repmgr/etc/repmgr.conf << 'EOF'
monitoring_history = yes
monitor_interval_secs = 5
failover = automatic
reconnect_attempts = 6
reconnect_interval = 5
promote_command = '/usr/local/pgsql/bin/repmgr -f /data/repmgr/etc/repmgr.conf --siblings-follow --log-to-file standby promote'
follow_command = '/usr/local/pgsql/bin/repmgr -f /data/repmgr/etc/repmgr.conf standby follow --log-to-file --upstream-node-id=%n'
log_level = INFO
log_status_interval = 120
log_file = '/data/repmgr/log/repmgr.log'
repmgrd_pid_file = '/data/repmgr/run/repmgr.pid'
repmgrd_service_start_command = '/usr/local/pgsql/bin/repmgrd -f /data/repmgr/etc/repmgr.conf --daemonize'
repmgrd_service_stop_command = 'kill `cat /data/repmgr/run/repmgr.pid`'
EOF
mkdir -pv /data/repmgr/{log,run}
touch /data/repmgr/log/repmgr.log
chown -R postgres:postgres /data/repmgr/

# 3. 两台主从都轮转日志
cat >> /etc/logrotate.conf << EOF
/data/repmgr/log/repmgr.log {
    missingok
    compress
    rotate 30
    daily
    dateext
    create 0644 postgres postgres
}
EOF

# 4. 两台主从都启动后台
cat > /etc/systemd/system/repmgrd.service << 'EOF'
[Unit]
Description=repmgr daemon
After=network.target postgresql5432.service
Wants=postgresql5432.service

[Service]
Type=forking
User=postgres
Group=postgres
PIDFile=/data/repmgr/run/repmgr.pid
ExecStart=/usr/local/pgsql/bin/repmgr -f /data/repmgr/etc/repmgr.conf daemon start
ExecStop=/usr/local/pgsql/bin/repmgr -f /data/repmgr/etc/repmgr.conf daemon stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start repmgrd
systemctl enable repmgrd
systemctl status repmgrd

# 5. 61 节点停止
systemctl stop postgresql5432

# 6. 62 节点查看日志
tail -f /data/repmgr/log/repmgr.log
# 插入数据
psql -d test -c "insert into t1 values(4);"

# 7. 61 节点恢复
# 成为 62 的从库
sudo -iu postgres repmgr -h 10.0.0.62 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind --dry-run
sudo -iu postgres repmgr -h 10.0.0.62 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind

# 查询数据
psql -d test -c "select * from t1;"

# 8. 62 节点停止
systemctl stop postgresql5432

# 9. 61 节点查看日志
tail -f /data/repmgr/log/repmgr.log
# 插入数据
psql -d test -c "insert into t1 values(5);"

# 10. 62 节点恢复
# 成为 61 的从库
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind --dry-run
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf node rejoin --force-rewind

# 查询数据
psql -d test -c "select * from t1;"
```

