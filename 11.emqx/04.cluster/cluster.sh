#节点	IP
#emqx01	10.0.0.71
#emqx02	10.0.0.72
#emqx03	10.0.0.73

#emqx01	10.0.0.71
docker pull emqx/emqx:4.4.3
mkdir -pv /data/emqx
cd /data/emqx || exit
docker volume create --name emqx-data
#/data/docker/volumes/emqx-data/_data
docker volume create --name emqx-log
#/data/docker/volumes/emqx-log/_data
docker volume create --name emqx-etc
#/data/docker/volumes/emqx-etc/_data
docker volume ls

cat > /data/emqx/docker-compose.yml <<EOF
version: '3'

services:
  emqx1:
    image: emqx/emqx:4.4.3
    container_name: emqx1
    environment:
      - EMQX_NAME=emqx01
      - EMQX_HOST=10.0.0.71
      - EMQX_NODE_NAME=emqx01@10.0.0.71
      - EMQX_CLUSTER__DISCOVERY=static
      - EMQX_CLUSTER__STATIC__SEEDS=emqx01@10.0.0.71,emqx02@10.0.0.72,emqx03@10.0.0.73
    network_mode: "host"
    healthcheck:
      test: ["CMD", "/opt/emqx/bin/emqx_ctl", "status"]
      interval: 5s
      timeout: 25s
      retries: 5
    volumes:
      - emqx-data:/opt/emqx/data
      - emqx-log:/opt/emqx/log
      - emqx-etc:/opt/emqx/etc
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped

volumes:
  emqx-data:
    external: true
  emqx-log:
    external: true
  emqx-etc:
    external: true
EOF
docker-compose up -d
docker-compose down
# 去认证+授权/外部 MySQL 数据库 配置

#emqx02	10.0.0.72
mkdir -pv /data/emqx
cd /data/emqx || exit
docker volume create --name emqx-data
#/data/docker/volumes/emqx-data/_data
docker volume create --name emqx-log
#/data/docker/volumes/emqx-log/_data
docker volume create --name emqx-etc
#/data/docker/volumes/emqx-etc/_data
docker volume ls
cat > /data/emqx/docker-compose.yml <<EOF
version: '3'

services:
  emqx2:
    image: emqx/emqx:4.4.3
    container_name: emqx2
    environment:
      - EMQX_NAME=emqx02
      - EMQX_HOST=10.0.0.72
      - EMQX_NODE_NAME=emqx02@10.0.0.72
      - EMQX_CLUSTER__DISCOVERY=static
      - EMQX_CLUSTER__STATIC__SEEDS=emqx01@10.0.0.71,emqx02@10.0.0.72,emqx03@10.0.0.73
    network_mode: "host"
    healthcheck:
      test: ["CMD", "/opt/emqx/bin/emqx_ctl", "status"]
      interval: 5s
      timeout: 25s
      retries: 5
    volumes:
      - emqx-data:/opt/emqx/data
      - emqx-log:/opt/emqx/log
      - emqx-etc:/opt/emqx/etc
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped

volumes:
  emqx-data:
    external: true
  emqx-log:
    external: true
  emqx-etc:
    external: true
EOF
docker-compose up -d
docker-compose down
# 去认证+授权/外部 MySQL 数据库 配置


#emqx03 10.0.0.73
docker pull emqx/emqx:4.4.3
mkdir -pv /data/emqx
cd /data/emqx || exit
docker volume create --name emqx-data
#/data/docker/volumes/emqx-data/_data
docker volume create --name emqx-log
#/data/docker/volumes/emqx-log/_data
docker volume create --name emqx-etc
#/data/docker/volumes/emqx-etc/_data
docker volume ls

cat > /data/emqx/docker-compose.yml <<EOF
version: '3'

services:
  emqx3:
    image: emqx/emqx:4.4.3
    container_name: emqx3
    environment:
      - EMQX_NAME=emqx03
      - EMQX_HOST=10.0.0.73
      - EMQX_NODE_NAME=emqx03@10.0.0.73
      - EMQX_CLUSTER__DISCOVERY=static
      - EMQX_CLUSTER__STATIC__SEEDS=emqx01@10.0.0.71,emqx02@10.0.0.72,emqx03@10.0.0.73
    network_mode: "host"
    healthcheck:
      test: ["CMD", "/opt/emqx/bin/emqx_ctl", "status"]
      interval: 5s
      timeout: 25s
      retries: 5
    volumes:
      - emqx-data:/opt/emqx/data
      - emqx-log:/opt/emqx/log
      - emqx-etc:/opt/emqx/etc
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped

volumes:
  emqx-data:
    external: true
  emqx-log:
    external: true
  emqx-etc:
    external: true
EOF
docker-compose up -d
docker-compose down
# 去认证+授权/外部 MySQL 数据库 配置