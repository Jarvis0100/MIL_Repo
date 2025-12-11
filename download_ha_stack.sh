#Download script
#!/bin/bash
set -euo pipefail
#Base Dir
# Base directory where RPMs and tarballs will be stored
BASE_DIR="${1:-$HOME/ha-db-offline/repo}"

echo "Using base directory: $BASE_DIR"
#echo
# Create directory structure
mkdir -p "$BASE_DIR"/{repos,postgresql,patroni,python,devtools,etcd,utils,keepalived,monitoring,haproxy,security}

# Ensure dnf download plugin is installed
sudo dnf -y install dnf-plugins-core

download_pkg_group() {
  local dest_dir="$1"
  shift
  mkdir -p "$dest_dir"
  echo "Downloading to: $dest_dir"
  sudo dnf download --resolve --destdir "$dest_dir" "$@"
}
#echo
echo "=== Downloading repository RPMs (for airgapped installation) ==="
download_pkg_group "$BASE_DIR/repos" \
  epel-release \
  pgdg-redhat-repo

echo "=== Downloading PostgreSQL 16 core RPMs (re-download for offline use) ==="
download_pkg_group "$BASE_DIR/postgresql" \
  postgresql16 \
  postgresql16-server \
  postgresql16-libs \
  postgresql16-contrib

echo "=== Downloading Patroni and related Python etcd client ==="
download_pkg_group "$BASE_DIR/patroni" \
  patroni \
  patroni-etcd
#python
# python3-etcd is already in python group but we include here to be safe
echo "=== Downloading Python runtime and libraries used by Patroni ==="
download_pkg_group "$BASE_DIR/python" \
  python3 \
  python3-libs \
  python3-pip \
  python3-setuptools \
  python3-psycopg2 \
  python3-requests \
  python3-urllib3 \
  python3-chardet \
  python3-idna \
  python3-dateutil \
  python3-six \
  python3-etcd \
  python3-dns \
  python3-prettytable \
  python3-click \
  python3-ydiff

echo "=== Downloading development tools (for building Python extensions if needed) ==="
download_pkg_group "$BASE_DIR/devtools" \
  gcc \
  gcc-c++ \
  python3-devel \
  glibc-devel \
  glibc-headers \
  kernel-headers \
  libxcrypt-devel

echo "=== Downloading system utilities ==="
download_pkg_group "$BASE_DIR/utils" \
  net-tools \
  bind-utils \
  telnet \
  nmap-ncat \
  lsof \
  psmisc \
  vim-enhanced \
  wget \
  tar

echo "=== Downloading Keepalived and dependencies (for VIP) ==="
download_pkg_group "$BASE_DIR/keepalived" \
  keepalived \
  ipvsadm

echo "=== Downloading security / SSL / CA packages ==="
download_pkg_group "$BASE_DIR/security" \
  openssl \
  openssl-libs \
  ca-certificates

echo "=== Downloading monitoring tools ==="
download_pkg_group "$BASE_DIR/monitoring" \
  sysstat \
  iotop \
  htop

echo "=== Downloading HAProxy and its dependencies ==="
download_pkg_group "$BASE_DIR/haproxy" \
  haproxy \
  pcre2 \
  systemd

echo "=== Downloading etcd tarball (not an RPM) ==="
ETCD_DIR="$BASE_DIR/etcd"
mkdir -p "$ETCD_DIR"
cd "$ETCD_DIR"

ETCD_VER="v3.5.16"
ETCD_TARBALL="etcd-${ETCD_VER}-linux-amd64.tar.gz"
ETCD_URL="https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/${ETCD_TARBALL}"

if [ ! -f "$ETCD_TARBALL" ]; then
  echo "Fetching $ETCD_TARBALL from $ETCD_URL"
  wget "$ETCD_URL"
else
  echo "etcd tarball already exists, skipping download"
fi

echo "All downloads completed."
echo "Files stored under: $BASE_DIR"

