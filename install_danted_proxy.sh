#!/bin/bash

# 1. Cập nhật và cài gói cần thiết
yum update -y || apt update -y
yum install gcc make pam-devel -y || apt install build-essential libpam0g-dev -y

# 2. Tải và giải nén mã nguồn Dante
cd /opt || exit 1
curl -LO https://www.inet.no/dante/files/dante-1.4.3.tar.gz
tar -xzf dante-1.4.3.tar.gz
cd dante-1.4.3/sockd || exit 1

# 3. Biên dịch sockd
make clean
make
cp sockd /usr/local/sbin/danted
chmod +x /usr/local/sbin/danted

# 4. Tạo user cho xác thực
useradd hongthai
echo "hongthai:CamShare" | chpasswd

# 5. Tạo file cấu hình Dante
cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log

internal: enX0 port = 1080
external: enX0

method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    method: username
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect error
}
EOF

# 6. Tạo log file
touch /var/log/danted.log
chmod 666 /var/log/danted.log

# 7. Tạo service danted
cat > /etc/systemd/system/danted.service <<EOF
[Unit]
Description=Dante SOCKS5 Proxy
After=network.target

[Service]
ExecStart=/usr/local/sbin/danted -f /etc/danted.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 8. Bật và khởi động service
systemctl daemon-reload
systemctl enable danted
systemctl restart danted
