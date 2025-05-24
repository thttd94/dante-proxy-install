#!/bin/bash

echo "🔧 Cài đặt các công cụ cần thiết..."
sudo dnf groupinstall "Development Tools" -y
sudo dnf install gcc make pam-devel curl tar -y

echo "📥 Tải và giải nén Dante..."
curl -O https://www.inet.no/dante/files/dante-1.4.3.tar.gz
tar -xzf dante-1.4.3.tar.gz
cd dante-1.4.3

echo "⚙️ Biên dịch Dante..."
./configure
make
sudo make install

echo "📝 Tạo file cấu hình /etc/danted.conf với interface enX0..."
cat <<EOF | sudo tee /etc/danted.conf
logoutput: /var/log/danted.log

internal: enX0 port = 1080
external: enX0

method: none
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect error
}
EOF

echo "📂 Tạo file log và phân quyền..."
sudo touch /var/log/danted.log
sudo chmod 666 /var/log/danted.log

echo "🧩 Tạo service systemd để quản lý danted..."
cat <<EOF | sudo tee /etc/systemd/system/danted.service
[Unit]
Description=Dante SOCKS5 Proxy
After=network.target

[Service]
ExecStart=/usr/local/sbin/danted -f /etc/danted.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Khởi động Dante..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable danted
sudo systemctl start danted

echo "📌 Nhớ mở cổng 1080 trong AWS Security Group!"



echo "✅ Hoàn tất! Mỗi lần reg được proxy thì cảm ơn Thái đẹp zai 1 tiếng nhé !"

