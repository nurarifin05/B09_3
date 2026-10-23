#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs
from html import escape
class App(BaseHTTPRequestHandler):
    def send(self, html, status=200):
        b=html.encode('utf-8'); self.send_response(status); self.send_header('Content-Type','text/html; charset=utf-8'); self.send_header('Content-Length',str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path == '/health': return self.send('OK')
        if self.path == '/asset.js': return self.send('console.log("lab demo");')
        if self.path == '/dummy-document': return self.send('<h2>Dokumen simulasi, tanpa data asli</h2>')
        if self.path == '/':
            extra = '<script src="http://keuangan.sibertaruna.my.id/asset.js"></script><a id="archive-download" href="http://keuangan.sibertaruna.my.id/dummy-document">Unduh dokumen demo</a>' if False else '<p>Simulasi transaksi pembayaran, tanpa informasi asli.</p>'
            self.send('<h1>Portal Pembayaran Pendidikan</h1><p>LAB SSL/TLS Lokal</p><form method="POST" action="/login"><input name="username" placeholder="Username"><input name="password" type="password" placeholder="Password"><button>Login Dummy</button></form>'+extra)
        else: self.send('404',404)
    def do_POST(self):
        if self.path!='/login':return self.send('404',404)
        n=int(self.headers.get('Content-Length','0')); data=parse_qs(self.rfile.read(min(n,8192)).decode('utf-8','replace'))
        u=data.get('username',[''])[0];p=data.get('password',[''])[0]
        if u=='bendahara_demo_03' and p=='Simulasi-03!': self.send('<h2>Login dummy diterima</h2>')
        else:self.send('<h2>Login dummy tidak cocok</h2>',403)
ThreadingHTTPServer(('127.0.0.1',8088),App).serve_forever()
