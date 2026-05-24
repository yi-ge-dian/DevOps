# 权限控制：
# 1.启动插件：emqx_auth_mnesia
# 2.vim /etc/emqx.conf
# 关闭匿名登录
# allow_anonymous = false
# acl_nomatch = deny( 无 acl 匹配的时候禁止)
# 3. 增加用户
curl -v -X POST "http://127.0.0.1:8081/api/v4/auth_username" \
     -u "admin:public" \
     -H "Content-Type: application/json" \
     -d '{
         "username": "emqx_u",
         "password": "emqx_p"
     }'
# 4. 查看用户列表
curl -X GET "http://127.0.0.1:8081/api/v4/auth_username" -u "admin:public"
# 5. 删除用户
curl -X DELETE "http://127.0.0.1:8081/api/v4/auth_username/emqx_u" -u "admin:public"
# 6. 修改用户密码
curl -X PUT "http://127.0.0.1:8081/api/v4/auth_username/emqx_u" \
     -u "admin:public" \
     -H "Content-Type: application/json" \
     -d '{
         "password": "123456"
     }'
# 7. 发布主题限制
# -------------------------------------------------------------
# 方案 1 ： pub 和 sub 分开限制
# -------------------------------------------------------------
#// 规则1：允许订阅 haha
#{
#    "username": "emqx_u",
#    "topic": "haha",
#    "action": "sub",
#    "access": "allow"
#}
#
#// 规则2：允许发布到 haha
#{
#    "username": "emqx_u",
#    "topic": "haha",
#    "action": "pub",
#    "access": "allow"
#}
#
#// 规则3：拒绝所有其他订阅
#{
#    "username": "emqx_u",
#    "topic": "#",
#    "action": "sub",
#    "access": "deny"
#}
#
#// 规则4：拒绝所有其他发布
#{
#    "username": "emqx_u",
#    "topic": "#",
#    "action": "pub",
#    "access": "deny"
#}
curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "haha",
    "action": "sub",
    "access": "allow"
  }'

curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "haha",
    "action": "pub",
    "access": "allow"
  }'

curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "#",
    "action": "sub",
    "access": "deny"
  }'

curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "#",
    "action": "pub",
    "access": "deny"
  }'

# 如果是一次性导入
curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '[
    {
      "username": "emqx_u",
      "topic": "haha",
      "action": "sub",
      "access": "allow"
    },
    {
      "username": "emqx_u",
      "topic": "haha",
      "action": "pub",
      "access": "allow"
    },
    {
      "username": "emqx_u",
      "topic": "#",
      "action": "sub",
      "access": "deny"
    },
    {
      "username": "emqx_u",
      "topic": "#",
      "action": "pub",
      "access": "deny"
    }
  ]'


# -------------------------------------------------------------
# 方案 2 ： pub 和 sub 合并限制
# -------------------------------------------------------------
#
#// 规则1：允许发布和订阅 haha
#{
#    "username": "emqx_u",
#    "topic": "haha",
#    "action": "pubsub",
#    "access": "allow"
#}
#
#// 规则2：拒绝所有其他发布和订阅
#{
#    "username": "emqx_u",
#    "topic": "#",
#    "action": "pubsub",
#    "access": "deny"
#}
# 1. 添加允许规则（pubsub 同时控制发布和订阅）
curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "haha",
    "action": "pubsub",
    "access": "allow"
  }'

# 2. 添加拒绝所有规则
curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '{
    "username": "emqx_u",
    "topic": "#",
    "action": "pubsub",
    "access": "deny"
  }'
# 如果是一次性导入
curl -X POST "http://localhost:8081/api/v4/acl" \
  -u admin:public \
  -H "Content-Type: application/json" \
  -d '[
    {
      "username": "emqx_u",
      "topic": "haha",
      "action": "pubsub",
      "access": "allow"
    },
    {
      "username": "emqx_u",
      "topic": "#",
      "action": "pubsub",
      "access": "deny"
    }
  ]'
# 查看规则
curl -X GET "http://localhost:8081/api/v4/acl/username/emqx_u" \
  -u admin:public
# 删除规则
curl -X DELETE "http://localhost:8081/api/v4/acl/username/emqx_u/haha" \
  -u admin:public

# 修改规则 = 先删除再添加

# 7. 添加完成后，记得在dashboard 的应用中禁用该账户，禁止通过 http api 发请求，有需要再开启