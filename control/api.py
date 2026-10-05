import re

from flask import Flask, jsonify, request
from waitress import serve

from db import init_db, redeem_code

app = Flask(__name__)
CODE_RE = re.compile(r"^[A-Z0-9]{16}$")


@app.get("/health")
def health():
    return jsonify(ok=True)


@app.post("/redeem")
def redeem():
    body = request.get_json(silent=True) or {}
    code = str(body.get("code", "")).strip().upper()

    if not CODE_RE.fullmatch(code):
        return jsonify(ok=False, error="invalid_format"), 400

    remote_ip = (
        request.headers.get("X-Real-IP")
        or request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
        or request.remote_addr
        or ""
    )

    if not redeem_code(code, remote_ip):
        return jsonify(ok=False, error="invalid_expired_or_used"), 403

    return jsonify(ok=True)


if __name__ == "__main__":
    init_db()
    serve(app, host="127.0.0.1", port=9100, threads=4)
