#!/bin/bash

[[ -e $(which curl) ]] && grep -q "1.1.1.1" /etc/resolv.conf || { 
    echo "nameserver 1.1.1.1" | cat - /etc/resolv.conf >> /etc/resolv.conf.tmp && mv /etc/resolv.conf.tmp /etc/resolv.conf
}

clear

# Package
apt update
apt install curl -y
apt install dos2unix -y

# Repository
rm -fr /etc/udp*
mkdir -p /etc/udp-custom
cd /etc/udp-custom

# Copy Code & Create Config
wget --no-check-certificate -O udp-custom-linux-amd64 "https://raw.githubusercontent.com/Rerechan02/UDP/main/bin/udp-custom-linux-amd64"
echo -e '{
  "listen": ":36711",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}' > /etc/udp-custom/config.json

# Permision
cd /etc/udp-custom
chmod +x udp-custom-linux-amd64
chmod +x config.json

# Membuat Service
cd /etc/systemd/system
echo -e '[Unit]
Description=Udp Custom By FN Project

[Service]
User=root
Type=simple
ExecStart=/etc/udp-custom/udp-custom-linux-amd64  --config /etc/udp-custom/config.json --exclude 7100,7200,7300,7400,7500,7600,7700,7800,7900,5300,5053,53,5353,443,80,8080,2082,8443,9443,22,3303,109,111,17071,1771,17070,7070,51820,3,6
WorkingDirectory=/etc/udp-custom/
Restart=Always
RestartSec=2s

[Install]
WantedBy=default.target' > udp-custom.service

# Menyalakan Service
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# Filer
cd