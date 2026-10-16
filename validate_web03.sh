#!/usr/bin/env bash
set -Eeuo pipefail
DOMAIN=web03.lab.example.com
IP=192.168.36.231
BASE=/etc/ssl/web03
fail(){ echo "[GAGAL] $*"; exit 1; }
ok(){ echo "[LULUS] $*"; }
[[ $EUID -eq 0 ]] || fail 'Gunakan sudo.'
systemctl is-active --quiet lighttpd || fail 'lighttpd tidak aktif'
/usr/sbin/lighttpd -tt -f /etc/lighttpd/lighttpd.conf || fail 'konfigurasi tidak valid'
ok 'lighttpd aktif dan sintaks valid'
served="$(echo | openssl s_client -connect "$IP:443" -servername "$DOMAIN" -showcerts 2>/dev/null)"
count="$(grep -c 'BEGIN CERTIFICATE' <<< "$served" || true)"
[[ "$count" -ge 2 ]] || fail "server hanya mengirim $count sertifikat, intermediate belum tersaji"
ok "server mengirim $count sertifikat"
openssl verify -CAfile "$BASE/ca.crt" -untrusted "$BASE/intermediate.crt" -verify_hostname "$DOMAIN" "$BASE/server.crt" >/dev/null || fail 'sertifikat lokal tidak valid'
code="$(curl --noproxy '*' --cacert "$BASE/ca.crt" --resolve "$DOMAIN:443:$IP" -sS -o /dev/null -w '%{http_code}' "https://$DOMAIN/health")" || fail 'curl TLS gagal tanpa -k'
[[ "$code" == 200 ]] || fail "health HTTP $code"
ok 'CA, hostname, chain dan health 200 valid tanpa -k'
if curl --noproxy '*' --cacert "$BASE/ca.crt" --resolve "wrong.web03.lab.example.com:443:$IP" -fsS -o /dev/null "https://wrong.web03.lab.example.com/health" 2>/dev/null; then
 fail 'Hostname lain tidak seharusnya lolos'
fi
ok 'hostname yang salah ditolak'
echo 'FLAG{WEB03_CHAIN_VALID}'
