pg 数据库创建用户

```sql
-- 创建用户
CREATE
USER prometheus WITH PASSWORD 'prometheus'
-- 将监控权限赋予给 prometheus 用户
GRANT pg_monitor TO prometheus
psql -h localhost -U prometheus -d postgres
```

下载 pg_exporter

```shell
cd /usr/local
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.19.1/postgres_exporter-0.19.1.linux-amd64.tar.gz
tar xvf postgres_exporter-0.19.1.linux-amd64.tar.gz
cp -a postgres_exporter-0.19.1.linux-amd64/postgres_exporter /usr/local/bin/
postgres_exporter --version
```

启动 systemd 服务

```shell
useradd -r -s /sbin/nologin prometheus
mkdir -pv /data/postgres_exporter
chown -R prometheus:prometheus /data/postgres_exporter
chown -R prometheus:prometheus /usr/local/bin/postgres_exporter
cat >/usr/lib/systemd/system/postgres_exporter5432.service <<EOF
[Unit]
Description=Prometheus PostgreSQL Exporter
After=network.target postgresql5432.service

[Service]
User=prometheus
Group=prometheus
Type=simple
Environment=DATA_SOURCE_NAME=postgresql://prometheus:prometheus@localhost:5432/postgres?sslmode=disable
ExecStart=/usr/local/bin/postgres_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start postgres_exporter5432
systemctl enable postgres_exporter5432
systemctl status postgres_exporter5432

curl http://localhost:9187/metrics
```

配置 prometheus 抓取 postgres_exporter

```yaml
  - job_name: 'postgres-exporter'
    static_configs:
      - targets:
        - 'your-postgres-exporter-server-ip:9187'
        - 'your-postgres-exporter-server-ip:9187'
```

重新加载 prometheus

```shell
curl -X POST http://localhost:9090/-/reload
```

大屏导入
https://grafana.com/grafana/dashboards/9628-postgresql-database/