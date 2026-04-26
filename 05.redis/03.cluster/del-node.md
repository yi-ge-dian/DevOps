1. 删除节点

主：10.0.0.181 6380

从：10.0.0.182 6380 --> 10.0.0.181 6380

2. 流程说明

确定节点下线是否存在槽slot，如果存在，需要先迁移槽slot，保证整个集群的slot的分配是完整的。

当下线的节点是从节点或者没有槽slot时，可以让集群的节点忘记该节点，然后下线，下线后关闭该服务

3. 获取节点信息

```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6380
# 记住集群节点信息
# M: 76cb15700eb45f1ead00f854ff36c1242cd24572 10.0.0.181:6380
#    slots:[0-1364],[5461-6826],[10923-12287] (4096 slots) master
# S: f69458d96673b3f03730473c506077bb8c807cc7 10.0.0.185:6379
#    slots: (0 slots) slave
#    replicates 49cd1ea849ff5576533ba072f6b9f4f3d0a6b799
# M: 49cd1ea849ff5576533ba072f6b9f4f3d0a6b799 10.0.0.181:6379
#    slots:[1365-5460] (4096 slots) master
#    1 additional replica(s)
# M: 52fc91e39de832535364d3cf8be47a19d7212ec0 10.0.0.183:6379
#    slots:[12288-16383] (4096 slots) master
#    1 additional replica(s)
# S: 2e1e93abfa54745d6aae52f558a523067570ded4 10.0.0.186:6379
#    slots: (0 slots) slave
#    replicates 4d21f9fb2d7a9108dde4bba4f7e364d2c08e804a
# M: 4d21f9fb2d7a9108dde4bba4f7e364d2c08e804a 10.0.0.182:6379
#    slots:[6827-10922] (4096 slots) master
#    1 additional replica(s)
# S: b351cd2c2bf5ffc1107fb64a1f5ddc770bd72d67 10.0.0.184:6379
#    slots: (0 slots) slave
#    replicates 52fc91e39de832535364d3cf8be47a19d7212ec0
# [OK] All nodes agree about slots configuration.
# >>> Check for open slots...
# >>> Check slots coverage...
# [OK] All 16384 slots covered.
```

4. 下线从节点
```shell
# redis -a 密码 --cluster del-node 下线节点ip:port 下线节点id
redis-cli -a 123456 --cluster del-node 10.0.0.182:6380 edd72e301bf7bd20f305250d712a3d3ca5fa04c5
```

5. 迁移槽slot
```shell
# redis -a 密码 --cluster reshard --cluster-from 下线主节点id --cluster-to 迁移至主节点id --cluster-slots 迁移槽数量 --cluster-yes 集群剩余节点ip:port
# 迁移槽数量为 1366，4096/3=1365.33，向上取整，所以迁移1366个槽
redis-cli -a 123456 --cluster reshard --cluster-from 76cb15700eb45f1ead00f854ff36c1242cd24572 --cluster-to 49cd1ea849ff5576533ba072f6b9f4f3d0a6b799 --cluster-slots 1366 --cluster-yes 10.0.0.181:6380

redis-cli -a 123456 --cluster reshard --cluster-from 76cb15700eb45f1ead00f854ff36c1242cd24572 --cluster-to 4d21f9fb2d7a9108dde4bba4f7e364d2c08e804a --cluster-slots 1366 --cluster-yes 10.0.0.181:6380

redis-cli -a 123456 --cluster reshard --cluster-from 76cb15700eb45f1ead00f854ff36c1242cd24572 --cluster-to 52fc91e39de832535364d3cf8be47a19d7212ec0 --cluster-slots 1366 --cluster-yes 10.0.0.181:6380
```

6. 查看集群信息
```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6379
```

7. 下线主节点
```shell
# redis -a 密码 --cluster del-node 下线节点ip:port 下线节点id
redis-cli -a 123456 --cluster del-node 10.0.0.181:6380 76cb15700eb45f1ead00f854ff36c1242cd24572

8. 查看集群信息
```shell
redis-cli -a 123456 --cluster check 10.0.0.181:6379
```

9. 关闭服务
```shell
# 181
systemctl stop redis6380
# 182
systemctl stop redis6380
```