#!/usr/bin/env python3
# ColoRight 桌面版 · 本地启动服务（只用 Python 自带库，无需安装任何包）
# 作用：1) 在本机打开编辑器页面  2) 把页面的 /comfy/* 请求转发到本机 ComfyUI
# 用法：python3 coloright_server.py [--comfy http://127.0.0.1:8188] [--port 8123] [--no-browser]
import http.client
import http.server
import json
import os
import sys
import urllib.parse
import webbrowser
from functools import partial

HERE = os.path.dirname(os.path.abspath(__file__))
COMFY = os.environ.get("COLORIGHT_COMFY", "http://127.0.0.1:8188").rstrip("/")
PORT = 8123
OPEN_BROWSER = True

args = sys.argv[1:]
for i, a in enumerate(args):
    if a == "--comfy" and i + 1 < len(args):
        COMFY = args[i + 1].rstrip("/")
    elif a == "--port" and i + 1 < len(args):
        PORT = int(args[i + 1])
    elif a == "--no-browser":
        OPEN_BROWSER = False

c = urllib.parse.urlparse(COMFY)
COMFY_HOST = c.hostname or "127.0.0.1"
COMFY_PORT = c.port or (443 if c.scheme == "https" else 80)
COMFY_TLS = c.scheme == "https"

HOP = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
       "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"}


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=HERE, **kw)

    def log_message(self, fmt, *a):  # quiet
        pass

    # ---- helpers ----
    def _json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _proxy(self, method):
        rest = self.path[len("/comfy"):] or "/"
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        # Drop browser-origin headers (Origin/Referer/Sec-Fetch-*/Expect): ComfyUI may
        # reject POSTs whose Origin does not match its own address (the page is served
        # from this launcher on a different port). As a server-side peer we forward
        # plain API requests, the same shape curl sends (which works).
        headers = {k: v for k, v in self.headers.items()
                   if k.lower() not in HOP and k.lower() not in ("origin", "referer", "expect")
                   and not k.lower().startswith("sec-fetch-")}
        conn_cls = http.client.HTTPSConnection if COMFY_TLS else http.client.HTTPConnection
        conn = conn_cls(COMFY_HOST, COMFY_PORT, timeout=120)
        try:
            conn.request(method, rest, body=body, headers=headers)
            resp = conn.getresponse()
            data = resp.read()
            self.send_response(resp.status, resp.reason)
            for k, v in resp.getheaders():
                if k.lower() not in HOP:
                    self.send_header(k, v)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            if method != "HEAD":
                self.wfile.write(data)
        except Exception as e:  # ComfyUI not reachable etc.
            self._json({"error": "无法连接 ComfyUI (%s:%s): %s" % (COMFY_HOST, COMFY_PORT, e)}, 502)
        finally:
            try:
                conn.close()
            except Exception:
                pass

    # ---- routes ----
    def do_GET(self):
        if self.path.startswith("/comfy/") or self.path == "/comfy":
            self._proxy("GET")
        elif self.path.startswith("/launcher-info"):
            self._json({"ok": True, "app": "coloright-desktop", "comfy_target": COMFY})
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith("/comfy/") or self.path == "/comfy":
            self._proxy("POST")
        else:
            self._json({"error": "not found"}, 404)

    def do_HEAD(self):
        if self.path.startswith("/comfy/"):
            self._proxy("HEAD")
        else:
            super().do_HEAD()


def main():
    port = PORT
    server = None
    for cand in range(PORT, PORT + 12):
        try:
            server = http.server.ThreadingHTTPServer(("127.0.0.1", cand), Handler)
            port = cand
            break
        except OSError:
            continue
    if server is None:
        print("启动失败：8123-8134 端口都被占用了")
        input("按回车退出")
        return
    url = "http://127.0.0.1:%d/" % port
    print("ColoRight 桌面版已启动")
    print("编辑器地址：" + url)
    print("ComfyUI 转发目标：" + COMFY)
    print("保持这个窗口开着，用完直接关掉即可。")
    if OPEN_BROWSER:
        try:
            webbrowser.open(url)
        except Exception:
            pass
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
