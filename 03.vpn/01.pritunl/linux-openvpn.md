1. 通过 pritunl ui 生成 .ovpn 后缀文件
2. 查看 openvpn 状态

```shell
systemctl status openvpn
yum -y install openvpn
```

3. 切换 root
```shell
vim /etc/openvpn/client/openvpn-user.txt
#username
#password
```

4. 将新建的 .ovpn 文件导入雄安云/etc/openvpn/client/目录下，并修改相关位置
```shell
cp xxx.ovpn /etc/openvpn/client/username.conf

vim /etc/openvpn/client/username.conf
auth-user-pass /etc/openvpn/client/openvpn-user.txt
```

5. 启动
```shell
systemctl start openvpn-client@username
```