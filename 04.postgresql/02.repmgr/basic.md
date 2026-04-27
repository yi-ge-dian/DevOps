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
