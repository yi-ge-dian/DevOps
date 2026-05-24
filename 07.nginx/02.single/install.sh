cd /usr/local/src

# nginx
wget http://nginx.org/download/nginx-1.30.0.tar.gz
tar -zxvf nginx-1.30.0.tar.gz
# zlib
wget http://zlib.net/zlib-1.3.2.tar.gz
tar -zxvf zlib-1.3.2.tar.gz
# pcre
wget https://mirrors.aliyun.com/exim/pcre/pcre-8.45.tar.gz
tar -zxvf pcre-8.45.tar.gz
# openssl
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.6/openssl-3.5.6.tar.gz
tar -zxvf openssl-3.5.6.tar.gz

cd /usr/local/src/nginx-1.30.0

./configure --prefix=/usr/local/nginx \
--with-zlib=../zlib-1.3.2 \
--with-openssl=../openssl-3.5.6 \
--with-pcre=../pcre-8.45 \
--with-stream_ssl_module \
--with-http_ssl_module \
--with-threads

make -j $(nproc) && make install

/usr/local/nginx/sbin/nginx -V
# 启动
/usr/local/nginx/sbin/nginx

# 停止
/usr/local/nginx/sbin/nginx -s stop

# 重启
/usr/local/nginx/sbin/nginx -s reload

# 查看进程
ps -ef | grep nginx

# 查看端口
netstat -ntlp | grep 80