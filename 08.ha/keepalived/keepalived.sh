# !/bin/bash
yum -y install keepalived

cp -a /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak

vim /etc/keepalived/keepalived.conf

# master
! Configuration file for keepalived
global_defs {
   router_id KP_node_01
}

vrrp_script check_pg {
    script /etc/keepalived/check_pg.sh
    interval 1
    timeout 30
    weight 10
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp1s0
    virtual_router_id 51
    priority 100
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        172.18.27.202
    }
    track_script {
        check_pg
  }
}

# slave
! Configuration file for keepalived
global_defs {
   router_id KP_node_02
}

vrrp_script check_pg {
    script /etc/keepalived/check_pg.sh
    interval 1
    timeout 30
    weight 10
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp1s0
    virtual_router_id 51
    priority 100
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        172.18.27.202
    }
    track_script {
        check_pg
  }
}


vim /etc/keepalived/check_pg.sh
#!/bin/bash
IS_RECOVERY=$(sudo -iu postgres -c psql -tAc 'SELECT pg_is_in_recovery();' 2>/dev/null)
if [ "$IS_RECOVERY" = "f" ]; then
    exit 0      # 是主库，返回成功，keepalived 增加 weight
else
    exit 1      # 是备库或查询失败，返回失败，keepalived 降低 weight
fi

systemctl daemon-reload
systemctl restart keepalived
systemctl enable keepalived

ping 172.18.27.202