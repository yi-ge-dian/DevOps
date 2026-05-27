# 权限控制：
#
# 1. 禁止匿名登录
cat >> /data/docker/volumes/emqx-etc/_data/emqx.conf <<EOF
allow_anonymous = false
acl_nomatch = deny
listener.tcp.external.proxy_protocol = on
EOF

# 2. 默认拒绝订阅发布
#  {allow, all}. 改为 {deny, all}
sed -i 's/{allow, all}./{deny, all}./g' /data/docker/volumes/emqx-etc/_data/acl.conf

# 3. 数据库修改
vim /data/docker/volumes/emqx-etc/_data/plugins/emqx_auth_mysql.conf
## MySQL 服务器地址
auth.mysql.server = 10.0.0.51:3306

## MySQL 用户名
auth.mysql.username = emqx

## MySQL 密码
auth.mysql.password = 123456

## MySQL 数据库名
auth.mysql.database = mqtt

## 连接池大小
auth.mysql.pool_size = 8

# 4.重启容器
docker-compose restart

# 5.部署数据库(参考数据库部署脚本)，创建数据库用户，注意修改ip地址，密码
mysql -u root -p123456
create database mqtt;
create user 'emqx'@'%' identified by '123456';
grant all privileges on mqtt.* to 'emqx'@'%';
flush privileges;
use mqtt;

# 认证表
CREATE TABLE `mqtt_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `salt` varchar(35) DEFAULT NULL,
  `is_superuser` tinyint(1) DEFAULT 0,
  `created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `mqtt_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# 权限表
CREATE TABLE `mqtt_acl` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `allow` int(1) DEFAULT 1 COMMENT '0: deny, 1: allow',
  `ipaddr` varchar(60) DEFAULT NULL COMMENT 'IpAddress',
  `username` varchar(100) DEFAULT NULL COMMENT 'Username',
  `clientid` varchar(100) DEFAULT NULL COMMENT 'ClientId',
  `access` int(2) NOT NULL COMMENT '1: subscribe, 2: publish, 3: pubsub',
  `topic` varchar(100) NOT NULL DEFAULT '' COMMENT 'Topic Filter',
  PRIMARY KEY (`id`),
  INDEX (ipaddr),
  INDEX (username),
  INDEX (clientid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# 6.dashboard 启用外部数据库认证权限
# 7.创建用户
insert into mqtt_user (username, password, salt, is_superuser, created) values ('emqx_u', sha2('123456', 256), null, 0, now());
# 8.删除用户
delete from mqtt.mqtt_user where username='emqx_u';

# 9.创建权限，emqx_u 可以订阅 emqx/#，发布 emqx/pub，发布订阅 emqx/subpub, 其他的都拒绝
insert into mqtt_acl (allow, ipaddr, username, clientid, access, topic) values (1, null, 'emqx_u', null, 1, 'sub');
insert into mqtt_acl (allow, ipaddr, username, clientid, access, topic) values (1, null, 'emqx_u', null, 2, 'pub');
insert into mqtt_acl (allow, ipaddr, username, clientid, access, topic) values (1, null, 'emqx_u', null, 3, 'subpub');
# 10.删除权限
delete from mqtt_acl where username = 'emqx_u';