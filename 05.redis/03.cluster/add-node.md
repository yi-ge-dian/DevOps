1. 添加节点

主：10.0.0.181 6380

从：10.0.0.182 6380 --> 10.0.0.181 6380

2. 准备工作

2.1. 如果是新节点，这两天节点全部安装 install-master.sh, 增加一些配置
```shell
cat >> /data/6379/data/redis.conf << EOF
######################################## cluster configuration
masterauth 123456
cluster-enabled yes
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-require-full-coverage no
EOF

systemctl restart redis6379
```
2.2. 如果是多实例
```shell
Port="6380"
# 创建目录
mkdir -pv /data/$Port/{data,etc,log,run,backup}
chown -R redis.redis /data/$Port/
chown -R redis.redis /usr/local/redis/
chmod 700 /data/$Port
cp -a /usr/local/redis/redis.conf /data/$Port/etc/redis.conf
# 配置 redis
cat >> /data/$Port/etc/redis.conf << EOF
####################################### basic configuration
bind 0.0.0.0
port  $Port
unixsocket /data/$Port/run/redis.sock
supervised systemd
dir /data/$Port/data
pidfile /data/$Port/run/redis.pid
logfile "/data/$Port/log/redis.log"
####################################### slow log configuration
slowlog-log-slower-than 100000
slowlog-max-len 128
####################################### connection configuration
maxclients 10000
requirepass 123456
maxmemory 1024MB
######################################## persistence configuration
appendonly yes
appendfilename "appendonly-$Port.aof"
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
######################################## cluster configuration
masterauth 123456
cluster-enabled yes
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-require-full-coverage no
EOF

# 配置 systemd
cat > /usr/lib/systemd/system/redis$Port.service << EOF
[Unit]
Description=Redis Server
After=network.target

[Service]
ExecStart=/usr/local/bin/redis-server /data/$Port/etc/redis.conf
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

# 启动 redis
systemctl daemon-reload
systemctl start redis$Port
systemctl status redis${Port}
```


3. 增加节点进入集群
```shell
# redis -a 密码 --cluster add-node 新主节点IP:端口 集群中任意一个节点IP:端口
redis-cli -a 123456 --cluster add-node 10.0.0.181:6380 10.0.0.181:6379
```
4. 查看集群状态
```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6379
# 记下新主节点的ID
# M: 76cb15700eb45f1ead00f854ff36c1242cd24572 10.0.0.181:6380
#   slots: (0 slots) master
```
5. 将新节点设置为从节点
```shell
# redis -a 密码 --cluster add-node --cluster-slave --cluster-master-id 主节点ID 新从节点IP:端口 集群中任意一个节点IP:端口
redis-cli -a 123456 --cluster add-node --cluster-slave --cluster-master-id 76cb15700eb45f1ead00f854ff36c1242cd24572 10.0.0.182:6380 10.0.0.181:6379
```
6. 查看集群状态
```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6379
# 记下新从节点的ID
#S: edd72e301bf7bd20f305250d712a3d3ca5fa04c5 10.0.0.182:6380
#   slots: (0 slots) slave
```
7. 将新主节点分配 slots
```shell
# redis -a 密码 --cluster reshard 集群中任意一个节点IP:端口
redis-cli -a 123456 --cluster reshard 10.0.0.181:6379
# 输入要分配的 slots 数量，比如 16384/4=4096
# 输入新主节点的ID 76cb15700eb45f1ead00f854ff36c1242cd24572
# 输入源节点ID，输入 all 表示从所有主节点中分配 slots 给新主节点
# 输入 yes 确认
```
8. 查看集群状态
```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6379
redis-cli -a 123456 --cluster info 10.0.0.181:6379