查看主库当前的状态

```shell
pg_controldata -D /data/5432/data
# Latest checkpoint location:           0/28F84168

# 含义：最新的检查点记录在 WAL 日志中的位置（日志序列号，LSN）,这是数据库崩溃恢复的起点。
# 作用：当数据库崩溃后重启，恢复过程会从“Latest checkpoint’s REDO location”开始重放 WAL 日志，一直应用到最新的 WAL。这个 LSN 是检查点记录自身的结束位置。

# Latest checkpoint's REDO location:    0/28F84130

# 含义：真正需要开始重放（REDO） 的 WAL 日志起始位置
# 作用：这个比上面的 Latest checkpoint location 略早（小）。检查点操作会确保直到这个 LSN 之前的所有数据修改都已经刷入磁盘。崩溃恢复时，就是从 “REDO location” 这个点开始重放后续的 WAL 日志。0/28E4D4C0 到 0/28E4D4F8 之间的 WAL 可能包含检查点记录本身。

# Latest checkpoint's REDO WAL file:    000000180000000000000028

# 含义：包含上述 REDO location 的 WAL 日志文件名。
# 作用：崩溃恢复时，PostgreSQL 需要从这个文件开始读取 WAL 日志。文件名（00000018 是 TimeLineID 24 的时间线历史部分，00000028 是日志文件序号）对应 WAL 位置 0/28000000。这告诉恢复过程从哪里开始找日志文件。
```

wal 文件介绍

```text
00000018 00000000 00000028
\________/ \______/ \______/
  Timeline   高32位   低32位
    (8位)    (8位)    (8位)

完整格式：{TimelineID}{LogID}{SegID}
总共 24 个十六进制字符（24 hex digits），每个部分 8 个十六进制字符（8 hex digits），
\
部分	值（十六进制）	十进制值	含义
TimelineID	00000018	24	时间线 ID
LogID（高32位）	00000000	0	WAL 逻辑日志文件号的高位部分
SegID（低32位）	00000028	40	WAL 逻辑日志文件号的低位部分
```

完整的逻辑文件序号：LogID (32位) + SegID (32位) = 0x0000000000000028 = 40

手动切换 wal 文件：
SELECT pg_switch_wal();

查看主从复制状态
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;
查看最慢的 lsn 对应的 wal 文件

清理
pg_archivecleanup -d /data/5432/archive  0000001800000005000000CE

慎重执行
find /data/5432/archive -name "*.history" -mtime +15 -delete
