# WEB-03 — Portal Pembayaran Pendidikan

**Ubuntu:** 192.168.36.197 | **Kali:** 192.168.36.230 | **Hostname:** keuangan.sibertaruna.my.id

## Instalasi
1. Set IP Ubuntu/Kali secara manual sesuai alokasi dan pastikan akses APT/mirror saat instalasi.
2. Copy `fullchain.pem` dan `sibertaruna.my.id.key` ke `Ubuntu/cert-input/` hanya pada Ubuntu. Jangan bagikan kunci privat ke Kali.
3. Ubuntu: `cd Ubuntu && sudo bash setup.sh` (HTTP belum HTTPS, untuk investigasi awal).
4. Kali: `cd Kali && sudo bash setup.sh`; sebagai user biasa jalankan `sslctf-info`.
5. Instruksi praktikum ada pada `Materi-Taruna/10_Soal_Flag_LMS.md`. Simpan snapshot sebelum taruna mengubah konfigurasi.
6. Dosen gunakan `Panduan-Dosen-RAHASIA/Panduan_Dosen_Lengkap.docx` untuk perintah langkah demi langkah.

**10 flag** + **15 soal PG**. Flag unik menurut lab, tetapi tetap deterministik dan harus dimasukkan ke LMS secara manual. Jangan beri folder Panduan-Dosen-RAHASIA kepada taruna.

**Penting:** Tes `curl -k` hanya mengecek konektivitas TLS, bukan kepercayaan sertifikat. Sertifikat publik dengan chain yang benar harus diverifikasi tanpa -k juga.
**Batasan:** Implementasi belum diuji di empat VM aktual; `lighttpd -tt`, browser, dan validator perlu uji end-to-end setelah pemasangan.

kalau error:
$ sudo systemctl status sslctf-app --no-pager
● sslctf-app.service - SSL CTF Dummy Portal
     Loaded: loaded (/etc/systemd/system/sslctf-app.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-10-23 23:19:18 WIB; 14s ago
   Main PID: 12327 (python3)
      Tasks: 1 (limit: 3453)
     Memory: 9.0M (peak: 9.3M)
        CPU: 303ms
     CGroup: /system.slice/sslctf-app.service
             └─12327 /usr/bin/python3 /opt/sslctf/app.py

Oct 23 23:19:18 ubuntu-desktop systemd[1]: Started sslctf-app.service - SSL CTF Dummy Portal.
ubuntu@ubuntu-desktop:~/Downloads/B09_3/Ubuntu$ sudo ss -lntp | grep 8088
LISTEN 0      5          127.0.0.1:8088      0.0.0.0:*    users:(("python3",pid=12327,fd=3))
ubuntu@ubuntu-desktop:~/Downloads/B09_3/Ubuntu$ curl -i http://127.0.0.1:8088/health
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 23 Oct 2026 16:19:46 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 2

OKubuntu@ubuntu-desktop:~/Downloads/B09_3/Ubuntu$ curl -i http://127.0.0.1/health
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 23 Oct 2026 16:19:54 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 2
Accept-Ranges: bytes

OKubuntu@ubuntu-desktop:~/Downloads/B09_3/Ubuntu$
ubuntu@ubuntu-desktop:~/Downloads/B09_3/Ubuntu$ curl -i http://192.168.36.197/
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 23 Oct 2026 16:20:50 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 299
Accept-Ranges: bytes

<h1>Portal Pembayaran Pendidikan</h1><p>LAB SSL/TLS Lokal</p><form method="POST" action="/login"><input name="username" placeholder="Username"><input name="password" type="password" placeholder="Password"><button>Login Dummy</button></form><p>Simulasi transaksi pembayaran, tanpa informasi asli.