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
