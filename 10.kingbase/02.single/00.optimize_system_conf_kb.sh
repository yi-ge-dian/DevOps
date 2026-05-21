#!/bin/bash
####################################################################################################################
###                                                                                                                                                                                                                                                                  
### Description: this script help us to make a base optimization for system
### Author : HM
### Create : 2020-04-28
###
### Usage  : bash optimize_system_conf.sh
###
####################################################################################################################
echo "This tool help use to make a base optimization for system"
echo ""

# ----------------------------------------------
# create user
# username kingbase
# password kingbase
# ----------------------------------------------
createKingbaseUserIfNotExist(){
  egrep "^kingbase" /etc/passwd >& /dev/null
  if [ $? -ne 0 ]
  then
    useradd -m -U kingbase
    echo kingbase|passwd --stdin kingbase
    echo "kingbase user is created."
  fi
}

# ----------------------------------------------
# optimize system conf
# ----------------------------------------------
optimizeSystemConf(){
  conf_exist=$(cat /etc/sysctl.conf|grep kingbase|wc -l)
  if [ $conf_exist -eq 0 ]; then
    echo "optimize system core conf"
    cat >> /etc/sysctl.conf <<EOF
#add by kingbase
#/proc/sys/kernel/优化
# 10000 connect remain:
kernel.sem = 250 162500 250 650

#notice: shall shmmax is base on 64GB, you may adjust it for your MEM
#for 16GB Mem:
#kernel.shmall = 3774873
#kernel.shmmax = 8589934592

#for 32GB Mem:
#kernel.shmall = 7549747
#kernel.shmmax = 17179869184
#for 64GB Mem:
kernel.shmall = 15099494
kernel.shmmax = 34359738368
#for 128GB Mem:
#kernel.shmall = 30198988
#kernel.shmmax = 68719476736
#for 256GB Mem:
#kernel.shmall = 60397977
#kernel.shmmax = 137438953472
#for 512GB Mem:
#kernel.shmall = 120795955
#kernel.shmmax = 274877906944

kernel.shmmni = 4096

vm.dirty_background_ratio=2
vm.dirty_ratio = 40

vm.overcommit_memory = 2
vm.overcommit_ratio = 90

vm.swappiness = 1

fs.aio-max-nr = 1048576
fs.file-max = 6815744
fs.nr_open = 20480000

# TCP端口使用范围
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 6000
# 记录的那些尚未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 65536
# 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.somaxconn=1024
net.core.netdev_max_backlog = 32768
net.core.wmem_default = 8388608
net.core.wmem_max = 1048576
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_syn_retries = 2
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_wmem = 8192 436600 873200
net.ipv4.tcp_rmem  = 32768 436600 873200
net.ipv4.tcp_mem = 94500000 91500000 92700000
net.ipv4.tcp_max_orphans = 3276800
EOF
    echo "system configuration is optimized."
  else
    echo "system configuration is already optimized, so we do nothing"
  fi
}

# ----------------------------------------------
# optimize limit conf
# ----------------------------------------------
optimizeLimitConf(){
  conf_exist=$(cat /etc/security/limits.conf | grep kingbase | wc -l)
  if [ $conf_exist -eq 0 ]; then
    echo "optimize limit configuration"
    cat >> /etc/security/limits.conf <<EOF
#add by kingbase
kingbase soft  nproc   65536
kingbase  hard  nproc   65536
kingbase  soft  nofile  65536
kingbase  hard  nofile  65536
kingbase  soft  stack   10240
kingbase  hard  stack   32768
kingbase soft core unlimited
kingbase hard core unlimited
EOF
    echo "limit is optimized."
  else
    echo "limit is already optimized, so we do nothing"
  fi

  if [ -f /etc/security/limits.d/90-nproc.conf ]; then
    conf_exist=$(cat /etc/security/limits.d/90-nproc.conf | grep kingbase | wc -l)
    if [ $conf_exist -eq 0 ]; then
      echo "90-nproc modifing"
      cat >> /etc/security/limits.d/90-nproc.conf <<EOF
kingbase soft nproc 65536
EOF
    else
      echo "90-nproc already modified, so we do nothing"
    fi
  elif [ -f /etc/security/limits.d/20-nproc.conf ]; then
    conf_exist=$(cat /etc/security/limits.d/20-nproc.conf | grep kingbase | wc -l)
    if [ $conf_exist -eq 0 ]; then
      echo "20-nproc modifing"
      cat >> /etc/security/limits.d/20-nproc.conf <<EOF
kingbase soft nproc 65536
EOF
    else
      echo "20-nproc already modified, so we do nothing"
    fi
  fi
}

# ----------------------------------------------
# optimize remove ipc
# ----------------------------------------------
optimizeRemoveIPC(){
  if [ -f /etc/systemd/logind.conf ]; then
    conf_exist=$(cat /etc/systemd/logind.conf|grep -i -E '^RemoveIPC'|wc -l)
    if [ $conf_exist -eq 1 ]; then
      sed -ie 's/RemoveIPC=yes/RemoveIPC=no/g' /etc/systemd/logind.conf
      echo "RemoveIPC is set to no."
    else
      echo "RemoveIPC=no" >> /etc/systemd/logind.conf
      echo "RemoveIPC is set to no."
    fi
  fi
}

# ----------------------------------------------
# optimize default tasks accounting
# ----------------------------------------------
optimizeDefaultTasksAccounting(){
  if [ -f /etc/systemd/system.conf ]; then
    conf_exist=$(cat /etc/systemd/system.conf|grep -i -E '^DefaultTasksAccounting'|wc -l)
    if [ $conf_exist -eq 1 ]; then
      sed -ie 's/DefaultTasksAccounting=yes/DefaultTasksAccounting=no/g' /etc/systemd/system.conf
      echo "DefaultTasksAccounting is set to no."
    else
      echo "DefaultTasksAccounting=no" >> /etc/systemd/system.conf
      echo "DefaultTasksAccounting is set to no."
    fi
  fi
}

# ----------------------------------------------
# main
# 1.createKingbaseUserIfNotExist
# 2.optimizeSystemConf
# 3.optimizeLimitConf
# 4.optimizeRemoveIPC
# 5.optimizeDefaultTasksAccounting
# ----------------------------------------------
echo "1.create kingbase user if not exists:"
createKingbaseUserIfNotExist
echo ""

echo "2.optimize system core configuration:"
optimizeSystemConf
sysctl -p >>/dev/null 2>&1
echo ""

echo "3.optimize limit:"
optimizeLimitConf
echo ""
echo "check limit:"
su - kingbase -c 'ulimit -a'|grep -E 'open files|max user processes'
echo ""

#4.optimize RemoveIPC
echo "4.optimize RemoveIPC"
optimizeRemoveIPC
echo ""

#5.optimize DefaultTasksAccounting
echo "5.optimize DefaultTasksAccounting"
optimizeDefaultTasksAccounting
echo ""
