import hashlib
import os
import secrets
import sqlite3
import time

DB_PATH = os.environ.get("DB_PATH", "/var/lib/golbert-control/codes.db")
CODE_TTL = int(os.environ.get("CODE_TTL", "900"))
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def connect():
    db = sqlite3.connect(DB_PATH, timeout=15)
    db.execute("PRAGMA journal_mode=WAL")
    return db


def init_db():
    with connect() as db:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS codes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                code_hash TEXT UNIQUE NOT NULL,
                created_at INTEGER NOT NULL,
                expires_at INTEGER NOT NULL,
                used_at INTEGER,
                used_ip TEXT,
                generated_by INTEGER
            )
            """
        )


def code_hash(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def generate_code(user_id: int) -> str:
    init_db()

    for _ in range(10):
        code = "".join(secrets.choice(ALPHABET) for _ in range(16))
        now = int(time.time())

        try:
            with connect() as db:
                db.execute(
                    """
                    INSERT INTO codes
                    (code_hash, created_at, expires_at, generated_by)
                    VALUES (?, ?, ?, ?)
                    """,
                    (code_hash(code), now, now + CODE_TTL, user_id),
                )
            return code
        except sqlite3.IntegrityError:
            continue

    raise RuntimeError("No se pudo generar un código único.")


def redeem_code(code: str, remote_ip: str) -> bool:
    init_db()
    now = int(time.time())

    with connect() as db:
        result = db.execute(
            """
            UPDATE codes
               SET used_at = ?, used_ip = ?
             WHERE code_hash = ?
               AND used_at IS NULL
               AND expires_at >= ?
            """,
            (now, remote_ip, code_hash(code), now),
        )
        return result.rowcount == 1
