# 允许 192.168.0.0/16 整个网段访问 Redis 默认端口 6379
sudo iptables -A INPUT -p tcp -s 192.168.0.0/16 --dport 6379 -j ACCEPT

# 拒绝其他所有 IP 访问 6379 端口（可选，但强烈推荐）
sudo iptables -A INPUT -p tcp --dport 6379 -j DROP

# 保存规则（不同发行版命令不同，例如 Ubuntu 用 netfilter-persistent）
sudo netfilter-persistent save