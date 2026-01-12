#!/usr/bin/env bash
set -euo pipefail

echo "[+] Pritunl Installer (Auto Ubuntu Detect)"

# Root kontrolü
if [[ $EUID -ne 0 ]]; then
  echo "[-] Lütfen root olarak çalıştırın (sudo -i)"
  exit 1
fi

# OS algılama
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "[-] OS algılanamadı"
  exit 1
fi

if [[ "$ID" != "ubuntu" ]]; then
  echo "[-] Sadece Ubuntu desteklenmektedir"
  exit 1
fi

UBUNTU_VERSION="$VERSION_ID"

case "$UBUNTU_VERSION" in
  "22.04")
    CODENAME="jammy"
    MONGODB_CODENAME="jammy"
    PRITUNL_REPO="stable"
    ;;
  "24.04")
    CODENAME="noble"
    MONGODB_CODENAME="jammy"   # MongoDB 8.0 henüz noble yok
    PRITUNL_REPO="unstable"   # Pritunl noble şu an unstable
    ;;
  *)
    echo "[-] Desteklenmeyen Ubuntu sürümü: $UBUNTU_VERSION"
    exit 1
    ;;
esac

echo "[+] Ubuntu $UBUNTU_VERSION ($CODENAME) algılandı"

# Gerekli paketler
apt update
apt install -y gnupg curl ca-certificates ufw

# Keyring dizini
mkdir -p /usr/share/keyrings

echo "[+] GPG keyler ekleniyor..."

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg

curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg \
  | gpg --dearmor --yes -o /usr/share/keyrings/openvpn-repo.gpg

curl -fsSL https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/pritunl.gpg

echo "[+] APT repository listeleri yazılıyor..."

cat > /etc/apt/sources.list.d/mongodb-org.list <<EOF
deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu ${MONGODB_CODENAME}/mongodb-org/8.0 multiverse
EOF

cat > /etc/apt/sources.list.d/openvpn.list <<EOF
deb [signed-by=/usr/share/keyrings/openvpn-repo.gpg] https://build.openvpn.net/debian/openvpn/stable ${CODENAME} main
EOF

cat > /etc/apt/sources.list.d/pritunl.list <<EOF
deb [signed-by=/usr/share/keyrings/pritunl.gpg] https://repo.pritunl.com/${PRITUNL_REPO}/apt ${CODENAME} main
EOF

echo "[+] UFW devre dışı bırakılıyor (Pritunl önerisi)"
ufw disable || true

echo "[+] Paket listesi güncelleniyor..."
apt update

echo "[+] Pritunl, MongoDB ve WireGuard kuruluyor..."
apt install -y pritunl mongodb-org wireguard-tools

echo "[+] Servisler başlatılıyor..."
systemctl enable mongod pritunl
systemctl start mongod pritunl

echo
echo "[✓] Kurulum tamamlandı"
echo "--------------------------------------------------"
echo "Ubuntu        : $UBUNTU_VERSION"
echo "MongoDB Repo  : $MONGODB_CODENAME"
echo "Pritunl Repo  : $PRITUNL_REPO"
echo
echo "Web Panel     : https://SUNUCU_IP"
echo "Setup Key     : pritunl setup-key"
echo "Admin Pass    : pritunl default-password"
echo
echo "Coded by Fatih Özdemir"
echo "--------------------------------------------------"
