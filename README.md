# WEB-03 — Broken Certificate Trust (Lighttpd / Ubuntu 24.04)

## Topologi
- Ubuntu Blue Team: 192.168.36.231, web03.lab.example.com
- Kali Red Team: 192.168.36.230
- Website HTTPS: https://web03.lab.example.com/health

## Ubuntu Blue Team
1. Pastikan VM telah memakai IP 192.168.36.231.
2. Jalankan `sudo bash setup.sh` dalam direktori ini.
3. Jalankan `sudo bash setup.sh --status`. Mode weak: HTTPS /health 200 jika diakses secara diagnostik tanpa validasi, tetapi curl dengan Root CA gagal karena intermediate tidak dikirim; jumlah sertifikat disajikan = 1.
4. File publik: `/etc/ssl/web03/ca.crt` (root), `/etc/ssl/web03/intermediate.crt`, `/etc/ssl/web03/server.crt`; **jangan bagikan *.key**.
5. Setelah investigasi, buat chain pada served.pem: `sudo sh -c 'cat /etc/ssl/web03/server.crt /etc/ssl/web03/intermediate.crt > /etc/ssl/web03/served.pem'`, lalu `sudo lighttpd -tt -f /etc/lighttpd/lighttpd.conf && sudo systemctl restart lighttpd`. Untuk mode pengajar otomatis: `sudo bash setup.sh --secure`.
6. Validator: `sudo bash validate_web03.sh`. Flag: `FLAG{WEB03_CHAIN_VALID}` jika semua lolos.
7. Reset untuk kelas berikut: `sudo bash setup.sh --reset-weak`.
8. Install ulang `sudo bash setup.sh` tidak akan menghapus mode secure yang sudah dicapai.

## Kali Red Team
1. Pastikan VM memakai IP 192.168.36.230.
2. Jalankan `sudo bash setup_kali.sh ubuntu` (ganti `ubuntu` jika akun Blue Team berbeda).
3. Verifikasi SSH fingerprint secara manual dengan membandingkan output `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` di Ubuntu.
4. Script memasang tools, /etc/hosts, root CA publik di trust store. Ia sengaja **tidak memasang intermediate** di trust store Kali.
5. Sebelum perbaikan `curl -Iv https://web03.lab.example.com/health` gagal; `curl -k https://web03.lab.example.com/health` hanya menguji ketersediaan, bukan keamanan.
6. Setelah perbaikan, `curl -fsS https://web03.lab.example.com/health` berhasil tanpa -k.
7. Audit chain: `echo | openssl s_client -connect 192.168.36.231:443 -servername web03.lab.example.com -showcerts 2>/dev/null | grep -c 'BEGIN CERTIFICATE'` (weak = 1, secure = 2).

## Penyelesaian manual vs penilaian
Soal 12 dapat diselesaikan manual dengan menyusun `served.pem` dari `server.crt` lalu `intermediate.crt`, menguji sintaks, dan me-restart lighttpd. Validator menilai **hasil nyata** TLS dan health check, bukan hanya penanda mode. Pengajar dapat memakai `setup.sh --secure` sebagai solusi otomatis setelah latihan.

## Keamanan
Isolasikan lab dari internet, gunakan hanya domain lab. Jangan memasang CA lab di komputer pribadi/produksi. Jangan distribusikan private keys. Jangan gunakan curl -k sebagai verifikasi final.

## Rujukan
https://redmine.lighttpd.net/projects/lighttpd/wiki/docs_ssl
