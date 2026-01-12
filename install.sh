#!/bin/bash
set -e

echo "[+] Pritunl + MongoDB 8.0 kurulumu (Ubuntu 22.04)"

if [ "$EUID" -ne 0 ]; then
  echo "[-] Root olarak çalıştırın (sudo -i)"
  exit 1
fi

apt update
apt install -y gnupg curl ca-certificates lsb-release ufw

mkdir -p /usr/share/keyrings

echo "[+] GPG key'ler ekleniyor..."

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg

curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg \
  | gpg --dearmor --yes -o /usr/share/keyrings/openvpn-repo.gpg

curl -fsSL https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/pritunl.gpg

echo "[+] Repository listeleri ekleniyor..."

cat > /etc/apt/sources.list.d/mongodb-org.list <<EOF
deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse
EOF

cat > /etc/apt/sources.list.d/openvpn.list <<EOF
deb [signed-by=/usr/share/keyrings/openvpn-repo.gpg] https://build.openvpn.net/debian/openvpn/stable jammy main
EOF

cat > /etc/apt/sources.list.d/pritunl.list <<EOF
deb [signed-by=/usr/share/keyrings/pritunl.gpg] https://repo.pritunl.com/stable/apt jammy main
EOF

echo "[+] UFW kapatılıyor (Pritunl için önerilir)"
ufw disable || true

apt update
apt install -y pritunl mongodb-org wireguard-tools

systemctl enable mongod pritunl
systemctl start mongod pritunl

echo
echo "[✓] Kurulum tamamlandı"
echo "--------------------------------------------------"
echo "Web Panel : https://SUNUCU_IP"
echo "Setup Key : pritunl setup-key"
echo "Admin Şifre: pritunl default-password"
echo "--------------------------------------------------"
