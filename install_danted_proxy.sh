#!/bin/bash

echo "🔧 Cập nhật hệ thống và cài gói phụ thuộc..."
sudo apt update
sudo apt install -y build-essential libpam0g-dev libwrap0-dev

echo "📥 Tải mã nguồn Dante và giải nén..."
cd /usr/local/src
sudo wget https://www.inet.no/dante/files/dante-1.4.3.tar.gz
sudo tar -xvzf dante-1.4.3.tar.gz
cd dante-1.4.3

echo "⚙️ Biên dịch và cài đặt Dante..."
sudo ./configure
sudo make
sudo make install

echo "📁 Tạo file cấu hình /etc/danted.conf..."
cat <<EOF | sudo tee /etc/danted.conf
logoutput: syslog
internal: enX0 port = 1080
external: enX0

method: username none
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

echo "⚙️ Tạo service systemd /etc/systemd/system/danted.service..."
cat <<EOF | sudo tee /etc/systemd/system/danted.service
[Unit]
Description=Dante SOCKS proxy daemon
After=network.target

[Service]
ExecStart=/usr/local/sbin/sockd -f /etc/danted.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reload systemd và khởi động dịch vụ..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable danted
sudo systemctl restart danted

echo "🧱 Mở cổng 1080 qua tường lửa..."
sudo ufw allow 1080/tcp

echo "✅ Hoàn tất! Kiểm tra dịch vụ:"
sudo systemctl status danted
sudo ss -tunlp | grep 1080




echo "✅ Hoàn tất! Mỗi lần reg được proxy thì cảm ơn Thái đẹp zai 1 tiếng nhé !"

