#!/bin/bash

set -e

echo -e "\e[33m[•] Memulai setup repository dan instalasi NGINX versi terbaru...\e[0m"

# Step 1: Persiapan awal
echo -e "\e[36m[1/5] Mengupdate sistem dan menginstal dependensi...\e[0m"
sudo apt update && sudo apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# Step 2: Tambahkan GPG key dari NGINX
echo -e "\e[36m[2/5] Menambahkan GPG key resmi NGINX...\e[0m"
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null

# Step 3: Tambahkan repository NGINX resmi (stable)
DISTRO_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
DISTRO_CODENAME=$(lsb_release -cs)
echo -e "\e[36m[3/5] Menambahkan repository nginx.org untuk $DISTRO_ID $DISTRO_CODENAME...\e[0m"
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/${DISTRO_ID} ${DISTRO_CODENAME} nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

# Step 4: Hapus nginx versi distro jika sudah ada
echo -e "\e[36m[4/5] Menghapus nginx versi lama (jika ada)...\e[0m"
sudo apt remove -y nginx nginx-common nginx-core || true

# Step 5: Install NGINX versi terbaru dari repository resmi
echo -e "\e[36m[5/5] Menginstal NGINX versi terbaru...\e[0m"
sudo apt update
sudo apt install -y nginx

# Final check
echo -e "\e[32m[✓] Instalasi selesai! Versi NGINX:\e[0m"
nginx -v
