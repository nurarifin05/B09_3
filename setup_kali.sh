#!/usr/bin/env bash
set -Eeuo pipefail
BLUE_IP=192.168.36.231
DOMAIN=web03.lab.example.com
BLUE_USER="${1:-ubuntu}"
[[ $EUID -eq 0 ]] || { echo 'Jalankan sudo bash setup_kali.sh ubuntu'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=300 update
apt-get -o DPkg::Lock::Timeout=300 install -y openssh-client openssl ca-certificates curl wget wireshark tshark tcpdump nmap unzip
sed -i '/[[:space:]]web03\.lab\.example\.com\([[:space:]]\|$\)/d' /etc/hosts
printf '%s %s\n' "$BLUE_IP" "$DOMAIN" >> /etc/hosts
mkdir -p /root/.ssh /root/web03-lab
chmod 700 /root/.ssh
printf '[KALI] Koneksi SSH pertama akan meminta validasi fingerprint.\n'
printf '[KALI] Bandingkan dengan output di Ubuntu: sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub\n'
ssh -o StrictHostKeyChecking=ask -o ConnectTimeout=12 "${BLUE_USER}@${BLUE_IP}" 'echo "[KALI] SSH host verified"'
scp -o StrictHostKeyChecking=yes "${BLUE_USER}@${BLUE_IP}:/etc/ssl/web03/ca.crt" /usr/local/share/ca-certificates/web03-lab-root.crt
chmod 644 /usr/local/share/ca-certificates/web03-lab-root.crt
update-ca-certificates
cp /usr/local/share/ca-certificates/web03-lab-root.crt /root/web03-lab/root-ca.crt
printf '\n[KALI] Root CA berhasil dipasang. Sebelum hardening, kegagalan curl normal:\n'
if curl --noproxy '*' -fsS "https://${DOMAIN}/health"; then
 echo '[KALI] HTTPS trusted: kemungkinan server sudah secure.'
else
 echo '[KALI] HTTPS trust gagal (expected bila intermediate belum dikirim).'
fi
printf '\n[KALI] Untuk membuktikan web tetap aktif TANPA validasi: curl -k https://%s/health (diagnostik saja).\n' "$DOMAIN"
printf '[KALI] JANGAN gunakan -k untuk bukti kelulusan.\n'
