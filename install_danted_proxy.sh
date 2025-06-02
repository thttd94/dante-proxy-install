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

# === Tạo user binmvt với pass KhongCoTien ===
PROXY_USER="AWS_HongThai"
PROXY_PASS="proxypro"

echo "👤 Tạo user $PROXY_USER ..."
sudo useradd -m "$PROXY_USER"
echo "$PROXY_USER:$PROXY_PASS" | sudo chpasswd

# === Lấy interface thật của máy ===
NET_IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "🌐 Interface sử dụng: $NET_IFACE"

echo "📁 Tạo file cấu hình /etc/danted.conf..."
cat <<EOF | sudo tee /etc/danted.conf
logoutput: syslog
internal: $NET_IFACE port = 443
external: $NET_IFACE

method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    log: connect disconnect error
    method: username
}
EOF

echo "⚙️ Tạo systemd service cho Dante..."
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

echo "🔄 Khởi động lại dịch vụ Dante..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable danted
sudo systemctl restart danted

echo "🧱 Mở cổng 443 qua tường lửa..."
sudo ufw allow 443/tcp

# === In kết quả cuối cùng ===
IP_ADDR=$(curl -s ifconfig.me)
echo "✅ SOCKS5 proxy đã sẵn sàng!"
echo "🔗 Proxy: $IP_ADDR:443:AWS_HongThai:proxypro"
echo "👉 Mỗi lần reg được proxy thì cảm ơn Thái đẹp zai 1 tiếng nhé 😎"
