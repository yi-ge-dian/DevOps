# 加入 --with-http_v2_module
cd /usr/local/src/nginx-1.30.0

./configure --prefix=/usr/local/nginx \
--with-zlib=../zlib-1.3.2 \
--with-openssl=../openssl-3.5.6 \
--with-pcre=../pcre-8.45 \
--with-stream_ssl_module \
--with-http_ssl_module \
--with-threads \
--with-http_v2_module

# 不要执行 make install，直接替换旧的 nginx 文件，手动把 obj 拷贝过去
make -j$(nproc)

# 备份旧的 nginx 文件
mv /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx_backup
cp -a /usr/local/src/nginx-1.30.0/objs/nginx /usr/local/nginx/sbin/nginx
/usr/local/nginx/sbin/nginx -V