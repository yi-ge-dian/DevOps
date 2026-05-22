#https://www.kingbase.com.cn/download.html#database_list?packageDrivenToolId=8
#软件版本：V8R6C8B14
#软件类型：数据库
#软件名称：KingbaseES_安装包

# 创建目录
mkdir -pv /usr/local/Kingbase/ES/V8
mkdir -pv /data/54321/{data,backup,archive}
chown -R kingbase:kingbase /data/54321
chown -R kingbase:kingbase /usr/local/kingbase
chmod 700 /data/54321

# 上传 kingbase 安装包到 /home/kingbase/
# 上传 license 文件到 /home/kingbase/
mount -o loop /home/kingbase/KingbaseES_V008R006C008B0014PS018_Kunpeng64_install.iso /mnt

su - kingbase
cd /mnt || exit
./setup.sh -i console

# y --> 完全按照 --> /home/kingbase/license_29296_0.dat --> /data/54321/data

# 切换为 root
/usr/local/Kingbase/ES/V8/install/script/root.sh


cat >> /etc/profile << EOF
export KINGBASE_HOME=/usr/local/kingbase/Server
export PATH=$KINGBASE_HOME/bin:$PATH
export KINGBASE_DATA=/data/54321/data
export LD_LIBRARY_PATH=/usr/local/kingbase/lib:$LD_LIBRARY_PATH
EOF
source /etc/profile


ksql -Usystem -d test

systemct status kingbase8d
systemctl start kingbase8d
systemctl enable kingbase8d
























