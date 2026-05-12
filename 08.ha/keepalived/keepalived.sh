# !/bin/bash
yum -y install keepalived

cp -a /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

vim /etc/keepalived/keepalived.conf

# master
! Configuration file for keepalived
global_defs {
   router_id pg_node_1
}

vrrp_script check_pg {
    script /etc/keepalived/check_pg.sh
    interval 1
    timeout 30
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        172.18.27.200
    }
    track_script {
        check_pg
  }
}

# slave
! Configuration file for keepalived
global_defs {
   router_id pg_node_2
}

vrrp_script check_pg {
    script /etc/keepalived/check_pg.sh
    interval 1
    timeout 30
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        172.18.27.200
    }
    track_script {
        check_pg
  }
}

vim /etc/keepalived/check_pg.sh

#!/bin/bash
count=`ps -ef | grep -w '/usr/local/pgsql/bin/postmaster' | grep -v grep | wc -l`
if [ ${count} -eq 0 ];then
  systemctl stop keepalived
fi

chmod +x /etc/keepalived/check_pg.sh
systemctl daemon-reload
systemctl restart keepalived
systemctl enable keepalived