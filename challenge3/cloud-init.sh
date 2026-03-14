#!/bin/bash
set -eux

# Cloud-init script for Ubuntu Linux
# Install nginx and create a simple "Hello, OpenTofu!" page and enable service

# Update system and installing nginx, wget, and tar
apt update
apt install -y nginx wget tar firewalld

# Enable nginx service
systemctl enable nginx
systemctl start nginx

# Configure firewall
systemctl enable firewalld
systemctl start firewalld

# Allow SSH (22), HTTP (80), and Node Exporter (9100)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-port=9100/tcp
firewall-cmd --reload

# Create a lightweight index page
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Hello, OpenTofu!</title></head>
  <body>
    <h1>Hello, OpenTofu!</h1>
    <p>Served from an VM provisioned by OpenTofu.</p>
  </body>
</html>
HTML

# Minimal nginx tuning for fast small-site serving (lightweight)
mkdir -p /etc/nginx/conf.d
cat > /etc/nginx/conf.d/open-tofu.conf <<'NGCONF'
server {
    listen       80;
    server_name  localhost;
    server_tokens off;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    keepalive_timeout 65;
    client_max_body_size 4M;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page  404              /404.html;

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
NGCONF

systemctl enable --now nginx
systemctl reload nginx || true

# Check Architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NODE_ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    NODE_ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Install Prometheus Node Exporter as a service
NODE_EXPORTER_VER=1.10.2
TMPDIR=/tmp/nodeexp
mkdir -p ${TMPDIR}
cd ${TMPDIR}
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/node_exporter-${NODE_EXPORTER_VER}.linux-${NODE_ARCH}.tar.gz
tar xzf node_exporter-${NODE_EXPORTER_VER}.linux-${NODE_ARCH}.tar.gz
install -m 0755 node_exporter-${NODE_EXPORTER_VER}.linux-${NODE_ARCH}/node_exporter /usr/local/bin/node_exporter || true
useradd --no-create-home --shell /bin/false node_exporter || true

cat > /etc/systemd/system/node_exporter.service <<'SVC'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload || true
systemctl enable --now node_exporter || true

# Done
echo "Cloud-init complete" >/var/log/cloud-init-otf.done
