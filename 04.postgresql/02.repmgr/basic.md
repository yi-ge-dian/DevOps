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
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone --dry-run
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone
# 123456 是 repmgr.conf 中的 password

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
su postgres
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.61
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.62
ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@10.0.0.63
```

4. 手动主从切换

62 节点执行

```shell
# 尝试切换
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --dry-run --force-rewind

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
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby switchover --siblings-follow --dry-run --force-rewind

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