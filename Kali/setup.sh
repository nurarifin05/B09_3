#!/usr/bin/env bash
set -Eeuo pipefail
(( EUID == 0 )) || { echo 'Jalankan sudo bash setup.sh'; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl openssl nmap tcpdump tshark wireshark-common ca-certificates python3
sed -i '/[[:space:]]keuangan.sibertaruna.my.id$/d' /etc/hosts
printf '%s %s\n' '192.168.36.197' 'keuangan.sibertaruna.my.id' >> /etc/hosts
install -m 755 "$HERE/validate.sh" /usr/local/bin/sslctf-validate
cat > /usr/local/bin/sslctf-info <<'INFO'
#!/usr/bin/env bash
echo 'WEB-03 | Portal Pembayaran Pendidikan'
echo 'Target keuangan.sibertaruna.my.id (192.168.36.197); Kali 192.168.36.230'
echo 'Username dummy: bendahara_demo_03'
echo 'Password dummy: Simulasi-03!'
echo 'Urutan: capture HTTP -> login HTTP -> evaluasi flag 1-2 -> instalasi HTTPS Lighttpd -> scan TLS -> hardening -> capture HTTPS -> validasi flag 3-10.'
echo 'Evidence: ~/sslctf-evidence/before.pcap, after.pcap, nmap-tls.txt'
INFO
chmod +x /usr/local/bin/sslctf-info
install -d -m 755 /etc/sslctf
echo '03' > /etc/sslctf/lab
echo 'Instalasi Kali selesai. Sebagai USER biasa: mkdir -p ~/sslctf-evidence; sslctf-info'
