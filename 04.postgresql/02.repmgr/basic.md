1. 环境规划

repmgr（监控复制过程、自动故障切换）+ witness（防止脑裂）+ keepalived（监控主库状态，自动切换VIP）

主库：10.0.0.61  + pg15.5 + postgis3.3 + repmgr5.4.1 [master]

备库：10.0.0.62  + pg15.5 + postgis3.3 + repmgr5.4.1 [slave]

仲裁：10.0.0.63  # todo


2. 安装 repmgr

61 主节点执行

```shell
bash install-pg-15.5-x86.sh
bash install-postgis-3.3-x86.sh
bash install-repmgr-master-x86.sh 10.0.0.61 1 primary
```
62 备节点执行

```shell
bash install-pg-15.5-x86.sh
bash install-postgis-3.3-x86.sh
bash install-repmgr-slave-x86-prepare.sh 10.0.0.62 2
```

61 62 都执行

```shell
su postgres
cat > ~/.pgpass << EOF
10.0.0.61:5432:repmgr:repmgr:123456
10.0.0.62:5432:repmgr:repmgr:123456
EOF
chmod 600 ~/.pgpass
exit
```

62 备节点执行
```shell
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone --dry-run
sudo -iu postgres repmgr -h 10.0.0.61 -U repmgr -d repmgr -f /data/repmgr/etc/repmgr.conf standby clone
# 123456 是 repmgr.conf 中的 password

systemctl start postgresql5432
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf standby register --upstream-node-id=1
sudo -iu postgres repmgr -f /data/repmgr/etc/repmgr.conf cluster show
```