#!/usr/bin/env python3
import http.client
import ssl
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

TARGET_HOST = "127.0.0.1"
TARGET_PORT = 8001
LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = 8000
CERT_PATH = Path(__file__).resolve().parent / "certs" / "localhost.pem"
KEY_PATH = Path(__file__).resolve().parent / "certs" / "localhost-key.pem"

HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class ReverseProxyHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _forward(self) -> None:
        body = None
        content_length = self.headers.get("Content-Length")
        if content_length:
            body = self.rfile.read(int(content_length))

        outgoing_headers = {
            k: v
            for k, v in self.headers.items()
            if k.lower() not in HOP_BY_HOP_HEADERS and k.lower() != "host"
        }
        # Préserve le Host original (ex: localhost:8000) au lieu de le remplacer par
        # celui du backend : Django s'en sert pour construire les URLs absolues des
        # médias (request.build_absolute_uri). Sans ça, les images renvoyées par l'API
        # pointent vers http://127.0.0.1:8001/... au lieu de https://localhost:8000/...,
        # ce qui est bloqué par le navigateur (mixed content) sur une page servie en HTTPS.
        outgoing_headers["Host"] = self.headers.get("Host", f"{TARGET_HOST}:{TARGET_PORT}")
        outgoing_headers["X-Forwarded-Proto"] = "https"

        conn = http.client.HTTPConnection(TARGET_HOST, TARGET_PORT, timeout=120)
        try:
            conn.request(self.command, self.path, body=body, headers=outgoing_headers)
            upstream = conn.getresponse()
            response_body = upstream.read()

            self.send_response(upstream.status, upstream.reason)
            for key, value in upstream.getheaders():
                lower_key = key.lower()
                if lower_key in HOP_BY_HOP_HEADERS:
                    continue
                if lower_key in {"date", "server"}:
                    continue
                if lower_key == "content-length":
                    continue
                self.send_header(key, value)
            self.send_header("Content-Length", str(len(response_body)))
            self.end_headers()
            if response_body:
                self.wfile.write(response_body)
        finally:
            conn.close()

    def do_GET(self) -> None:
        self._forward()

    def do_POST(self) -> None:
        self._forward()

    def do_PUT(self) -> None:
        self._forward()

    def do_PATCH(self) -> None:
        self._forward()

    def do_DELETE(self) -> None:
        self._forward()

    def do_OPTIONS(self) -> None:
        self._forward()

    def do_HEAD(self) -> None:
        self._forward()


def main() -> None:
    if not CERT_PATH.exists() or not KEY_PATH.exists():
        raise FileNotFoundError(
            f"Missing TLS certs at {CERT_PATH} and/or {KEY_PATH}. "
            "Generate them with mkcert first."
        )

    server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), ReverseProxyHandler)
    tls_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    tls_context.load_cert_chain(certfile=str(CERT_PATH), keyfile=str(KEY_PATH))
    server.socket = tls_context.wrap_socket(server.socket, server_side=True)

    print(
        f"HTTPS proxy listening on https://{LISTEN_HOST}:{LISTEN_PORT} "
        f"-> http://{TARGET_HOST}:{TARGET_PORT}"
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
