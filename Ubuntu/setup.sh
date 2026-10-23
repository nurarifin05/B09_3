#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "ERROR baris $LINENO: setup belum selesai" >&2' ERR
(( EUID == 0 )) || { echo 'Jalankan sudo bash setup.sh'; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
CERT="$HERE/cert-input/fullchain.pem"; KEY="$HERE/cert-input/sibertaruna.my.id.key"
[[ -s "$CERT" && -s "$KEY" ]] || { echo 'File certificate dan key belum ada di Ubuntu/cert-input/'; exit 2; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y lighttpd openssl python3 curl ca-certificates
openssl x509 -in "$CERT" -noout -checkend 0 >/dev/null
openssl pkey -in "$KEY" -noout >/dev/null
A="$(openssl x509 -in "$CERT" -pubkey -noout | openssl pkey -pubin -outform DER | sha256sum | cut -d' ' -f1)"
B="$(openssl pkey -in "$KEY" -pubout -outform DER | sha256sum | cut -d' ' -f1)"
[[ "$A" == "$B" ]] || { echo 'Key dan certificate tidak cocok'; exit 3; }
openssl x509 -in "$CERT" -noout -ext subjectAltName | grep -Fq '*.sibertaruna.my.id' || { echo 'Sertifikat bukan wildcard *.sibertaruna.my.id'; exit 4; }
install -d -m 700 /etc/ssl/sslctf
install -m 600 "$KEY" /etc/ssl/sslctf/server.key
install -m 644 "$CERT" /etc/ssl/sslctf/fullchain.pem
install -d -m 755 /opt/sslctf
install -m 644 "$HERE/app.py" /opt/sslctf/app.py
cat > /etc/systemd/system/sslctf-app.service <<'UNIT'
[Unit]
Description=SSL CTF Dummy Portal
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/sslctf/app.py
User=www-data
Group=www-data
Restart=always
NoNewPrivileges=true
ProtectSystem=strict
PrivateTmp=true
[Install]
WantedBy=multi-user.target
UNIT
mkdir -p /etc/lighttpd/conf-available /etc/lighttpd/conf-enabled
# Simpan konfigurasi yang sudah ada, tanpa menghapus unrelated config.
[[ ! -e /etc/lighttpd/lighttpd.conf.sslctf-backup ]] && cp /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.sslctf-backup
cat > /etc/lighttpd/conf-available/99-sslctf.conf <<'LIGHT'
server.bind = "0.0.0.0"
server.port = 80
server.modules += ( "mod_proxy" )
proxy.server = ( "" => ( ( "host" => "127.0.0.1", "port" => 8088 ) ) )
LIGHT
ln -sfn /etc/lighttpd/conf-available/99-sslctf.conf /etc/lighttpd/conf-enabled/99-sslctf.conf
# Default Lighttpd Ubuntu biasanya memakai /etc/lighttpd/conf-enabled/*.conf.
grep -Fq '/etc/lighttpd/conf-enabled/*.conf' /etc/lighttpd/lighttpd.conf || echo 'include_shell "cat /etc/lighttpd/conf-enabled/*.conf"' >> /etc/lighttpd/lighttpd.conf
sed -i '/[[:space:]]keuangan.sibertaruna.my.id$/d' /etc/hosts
printf '%s %s\n' '192.168.36.197' 'keuangan.sibertaruna.my.id' >> /etc/hosts
systemctl daemon-reload
/usr/sbin/lighttpd -tt -f /etc/lighttpd/lighttpd.conf
systemctl enable sslctf-app.service lighttpd.service
systemctl restart sslctf-app.service lighttpd.service
curl --noproxy '*' -fsS --max-time 8 --resolve 'keuangan.sibertaruna.my.id:80:192.168.36.197' 'http://keuangan.sibertaruna.my.id/health' >/dev/null
echo 'READY: HTTP aktif, HTTPS BELUM aktif. Snapshot VM sekarang.'
echo 'Sertifikat tersimpan aman di /etc/ssl/sslctf/. Lihat panduan dosen untuk konfigurasi HTTPS.'
