#!/bin/bash

set -e

echo -e "\n[🔧] Persiapan build environment..."
sudo apt update
sudo apt install -y build-essential git cmake golang curl unzip \
                    zlib1g-dev libpcre3 libpcre3-dev libssl-dev \
                    libxslt1-dev libgd-dev libgeoip-dev libgoogle-perftools-dev \
                    libatomic-ops-dev libxml2 libxml2-dev libedit-dev uuid-dev

echo -e "\n[🌐] Download source code NGINX 1.29.0..."
cd /usr/local/src
curl -O https://nginx.org/download/nginx-1.29.0.tar.gz
tar -xzf nginx-1.29.0.tar.gz

echo -e "\n[🧪] Clone BoringSSL untuk QUIC/HTTP3..."
git clone https://github.com/google/boringssl.git
mkdir -p boringssl/build && cd boringssl/build
cmake .. && make
cd /usr/local/src

echo -e "\n[📦] Clone plugin tambahan (Brotli, Headers More)..."
git clone --recursive https://github.com/google/ngx_brotli.git
git clone https://github.com/openresty/headers-more-nginx-module.git

echo -e "\n[⚙️] Konfigurasi build NGINX dengan semua modul..."
cd nginx-1.29.0

./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/run/nginx.pid \
  --lock-path=/var/lock/nginx.lock \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_secure_link_module \
  --with-http_degradation_module \
  --with-http_slice_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-threads \
  --with-file-aio \
  --with-http_random_index_module \
  --with-cc-opt="-I../boringssl/include" \
  --with-ld-opt="-L../boringssl/build/ssl -L../boringssl/build/crypto" \
  --add-module=../ngx_brotli \
  --add-module=../headers-more-nginx-module

echo -e "\n[🔨] Mulai kompilasi..."
make -j$(nproc)
sudo make install

echo -e "\n[✅] Instalasi NGINX 1.29.0 selesai!"
#nginx -v
