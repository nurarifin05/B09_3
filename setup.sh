#!/usr/bin/env bash
set -Eeuo pipefail
DOMAIN=web03.lab.example.com
BLUE_IP=192.168.36.231
BASE=/etc/ssl/web03
CFG=/etc/lighttpd/lighttpd.conf
MODE=/var/lib/web03/mode
SITE=/var/www/web03
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log(){ printf '[WEB03] %s\n' "$*"; }
trap 'echo "[WEB03][ERROR] Baris $LINENO gagal. Periksa: journalctl -u lighttpd -n 50 --no-pager" >&2' ERR
[[ $EUID -eq 0 ]] || { echo 'Jalankan dengan sudo.'; exit 1; }
apt_safe(){ DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 "$@"; }
check_ip(){ ip -4 -o addr show | grep -q "${BLUE_IP}/" || log "PERINGATAN: IP ${BLUE_IP} tidak ditemukan pada interface; atur IP VM terlebih dahulu."; }
map_host(){ sed -i '/[[:space:]]web03\.lab\.example\.com\([[:space:]]\|$\)/d' /etc/hosts; printf '%s %s\n' "$BLUE_IP" "$DOMAIN" >> /etc/hosts; }
certs(){
 mkdir -p "$BASE"; chmod 755 "$BASE"
 if [[ ! -s "$BASE/ca.crt" || ! -s "$BASE/intermediate.crt" || ! -s "$BASE/server.crt" ]]; then
  log 'Membuat Root CA, Intermediate CA, dan leaf server (hanya lab)...'
  openssl genrsa -out "$BASE/ca.key" 3072 >/dev/null 2>&1
  openssl req -new -x509 -sha256 -days 3650 -key "$BASE/ca.key" -out "$BASE/ca.crt" -subj '/CN=WEB03 Lab Root CA/O=WEB03 CTF' -addext 'basicConstraints=critical,CA:TRUE,pathlen:1' -addext 'keyUsage=critical,keyCertSign,cRLSign' >/dev/null 2>&1
  openssl genrsa -out "$BASE/intermediate.key" 3072 >/dev/null 2>&1
  openssl req -new -sha256 -key "$BASE/intermediate.key" -out "$BASE/intermediate.csr" -subj '/CN=WEB03 Lab Intermediate CA/O=WEB03 CTF' >/dev/null 2>&1
  cat > "$BASE/intermediate.ext" <<'EOT'
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOT
  openssl x509 -req -in "$BASE/intermediate.csr" -CA "$BASE/ca.crt" -CAkey "$BASE/ca.key" -CAcreateserial -out "$BASE/intermediate.crt" -days 1800 -sha256 -extfile "$BASE/intermediate.ext" >/dev/null 2>&1
  openssl genrsa -out "$BASE/server.key" 2048 >/dev/null 2>&1
  openssl req -new -sha256 -key "$BASE/server.key" -out "$BASE/server.csr" -subj "/CN=$DOMAIN/O=WEB03 CTF" >/dev/null 2>&1
  cat > "$BASE/server.ext" <<EOT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$DOMAIN
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOT
  openssl x509 -req -in "$BASE/server.csr" -CA "$BASE/intermediate.crt" -CAkey "$BASE/intermediate.key" -CAcreateserial -out "$BASE/server.crt" -days 365 -sha256 -extfile "$BASE/server.ext" >/dev/null 2>&1
 fi
 cat "$BASE/server.crt" "$BASE/intermediate.crt" > "$BASE/fullchain.pem"
 cp "$BASE/server.crt" "$BASE/served.pem"
 chmod 644 "$BASE"/*.crt "$BASE"/*.pem
 chmod 600 "$BASE"/*.key
 openssl verify -CAfile "$BASE/ca.crt" -untrusted "$BASE/intermediate.crt" "$BASE/server.crt"
}
write_config(){
 cat > "$CFG" <<EOT
server.modules = ( "mod_access", "mod_openssl" )
server.document-root = "$SITE"
server.port = 80
server.username = "www-data"
server.groupname = "www-data"
server.errorlog = "/var/log/lighttpd/error.log"
index-file.names = ( "index.html" )
mimetype.assign = ( ".html" => "text/html", ".txt" => "text/plain", ".css" => "text/css" )
\$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "$BASE/served.pem"
    ssl.privkey = "$BASE/server.key"
    ssl.openssl.ssl-conf-cmd = ( "MinProtocol" => "TLSv1.2" )
}
EOT
}
apply_mode(){
 local requested="$1"
 [[ -s "$BASE/server.crt" ]] || { echo 'Jalankan sudo bash setup.sh terlebih dahulu.'; exit 1; }
 if [[ "$requested" == secure ]]; then
  cp "$BASE/fullchain.pem" "$BASE/served.pem"
 else
  cp "$BASE/server.crt" "$BASE/served.pem"
 fi
 chmod 644 "$BASE/served.pem"
 /usr/sbin/lighttpd -tt -f "$CFG"
 systemctl restart lighttpd
 systemctl is-active --quiet lighttpd
 mkdir -p /var/lib/web03; echo "$requested" > "$MODE"
 log "Mode: $requested"
}
status(){
 log "Domain: $DOMAIN -> $BLUE_IP"
 log "Mode: $(cat "$MODE" 2>/dev/null || echo unknown)"
 systemctl is-active lighttpd || true
 /usr/sbin/lighttpd -tt -f "$CFG" || true
 log "HTTPS /health HTTP: $(curl --noproxy '*' -k -s -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:$BLUE_IP" "https://$DOMAIN/health" || true)"
 log "Dengan Root CA (tanpa -k):"
 if curl --noproxy '*' --cacert "$BASE/ca.crt" -sS -o /dev/null --resolve "$DOMAIN:443:$BLUE_IP" "https://$DOMAIN/health"; then
  log 'CHAIN VERIFIED'
 else
  log 'CHAIN FAILED (diharapkan dalam mode weak)'
 fi
 log "Jumlah sertifikat disajikan: $(echo | openssl s_client -connect "$BLUE_IP:443" -servername "$DOMAIN" -showcerts 2>/dev/null | grep -c 'BEGIN CERTIFICATE' || true)"
}
case "${1:-install}" in
 --status) status; exit 0;;
 --secure) apply_mode secure; status; exit 0;;
 --reset-weak) apply_mode weak; status; exit 0;;
 install|--install) ;;
 *) echo 'Pemakaian: sudo bash setup.sh [--status|--secure|--reset-weak]'; exit 2;;
esac
check_ip
log 'Update repository dan instal dependensi...'
apt_safe update
apt_safe install -y lighttpd openssl ca-certificates curl wget openssh-server tcpdump tshark unzip python3 iproute2
log 'Cek konflik port 80/443...'
for svc in apache2 nginx; do
 if systemctl is-active --quiet "$svc" 2>/dev/null; then
  log "Menghentikan $svc karena port dibutuhkan lighttpd"; systemctl disable --now "$svc"
 fi
done
map_host
certs
mkdir -p "$SITE" /var/lib/web03
cat > "$SITE/index.html" <<'EOT'
<!doctype html><html lang="id"><meta charset="utf-8"><title>WEB-03 PKI Lab</title><h1>WEB-03 — Broken Certificate Trust</h1><p>Server simulasi akademik. Selidiki rantai sertifikat HTTPS.</p><p>Health: <a href="/health">/health</a></p></html>
EOT
printf 'WEB03 HEALTH OK\n' > "$SITE/health"
chown -R www-data:www-data "$SITE"
write_config
systemctl enable --now ssh
# preserve secure mode on repeat install; do not reset a completed student exercise
if [[ -f "$MODE" && $(cat "$MODE") == secure ]]; then apply_mode secure; else apply_mode weak; fi
log "Root CA PUBLIK untuk Kali: $BASE/ca.crt"
log "Leaf: $BASE/server.crt | Intermediate: $BASE/intermediate.crt"
log 'JANGAN salin atau unggah *.key'
status
