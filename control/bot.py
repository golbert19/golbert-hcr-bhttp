import os
import time

import requests

from db import CODE_TTL, generate_code, init_db

BOT_TOKEN = os.environ["BOT_TOKEN"]
ADMIN_IDS = {
    int(x.strip())
    for x in os.environ.get("ADMIN_IDS", "").split(",")
    if x.strip()
}

API = f"https://api.telegram.org/bot{BOT_TOKEN}"


def tg(method, **data):
    response = requests.post(f"{API}/{method}", data=data, timeout=55)
    response.raise_for_status()
    return response.json()


def send(chat_id, text):
    tg("sendMessage", chat_id=chat_id, text=text)


def main():
    init_db()

    try:
        tg("deleteWebhook", drop_pending_updates="false")
    except Exception:
        pass

    offset = 0

    while True:
        try:
            result = requests.get(
                f"{API}/getUpdates",
                params={"timeout": 45, "offset": offset},
                timeout=55,
            )
            result.raise_for_status()

            for update in result.json().get("result", []):
                offset = update["update_id"] + 1
                message = update.get("message") or {}
                text = (message.get("text") or "").strip()

                if not text:
                    continue

                chat_id = message.get("chat", {}).get("id")
                user_id = message.get("from", {}).get("id")

                if text.startswith("/start"):
                    send(
                        chat_id,
                        "Golbert VPS Control\n\n"
                        "/codigo - generar código de instalación de un solo uso",
                    )

                elif text.startswith("/codigo"):
                    if user_id not in ADMIN_IDS:
                        send(chat_id, "No autorizado.")
                        continue

                    code = generate_code(user_id)
                    send(
                        chat_id,
                        f"Código: {code}\n"
                        f"Uso: una sola vez\n"
                        f"Validez: {CODE_TTL // 60} minutos",
                    )

        except Exception as exc:
            print(f"Telegram error: {exc}", flush=True)
            time.sleep(5)


if __name__ == "__main__":
    main()
