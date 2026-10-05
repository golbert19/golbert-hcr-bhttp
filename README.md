# Golbert VPS

Base modular para Ubuntu 22.04.

## Puertos

- HCR gateway: TCP 8180
- BHTTP gateway: TCP 8080
- BadVPN UDPGW: TCP 7300, ligado a 127.0.0.1 por defecto
- API de control: 127.0.0.1:9100
- Nginx de control: 80/443

## Importante sobre HCR/BHTTP

Los servicios `golbert-hcr` y `golbert-bhttp` incluidos aquí son gateways TCP aislados
que reenvían hacia SSH. Esto deja puertos, systemd, firewall, logs y reinicios listos,
pero NO afirma implementar un handshake propietario HCR/BHTTP.

Cuando se disponga del backend compatible real, solo hay que sustituir `ExecStart`
de `systemd/golbert-hcr.service` y/o `systemd/golbert-bhttp.service`; BadVPN,
BBR, bot y validación no necesitan cambiar.

## Estructura

```text
golbert-vps/
├── bootstrap.sh
├── install.sh
├── menu.sh
├── uninstall.sh
├── config/
│   └── defaults.env
├── lib/
│   └── common.sh
├── modules/
│   ├── hcr.sh
│   ├── bhttp.sh
│   ├── badvpn.sh
│   ├── optimizer.sh
│   └── firewall.sh
├── systemd/
│   ├── golbert-hcr.service
│   ├── golbert-bhttp.service
│   └── golbert-badvpn.service
└── control/
    ├── api.py
    ├── bot.py
    ├── db.py
    ├── requirements.txt
    ├── golbert-control.env.example
    ├── install-control.sh
    ├── systemd/
    │   ├── golbert-control-api.service
    │   └── golbert-control-bot.service
    └── nginx/
        └── golbert-control.conf.example
```

## Instalación rápida

1. Edita `config/defaults.env` y cambia `CONTROL_URL`.
2. En el VPS de control ejecuta `sudo bash control/install-control.sh`.
3. Edita `/etc/golbert-control.env` con tu BOT_TOKEN y ADMIN_IDS.
4. Configura Nginx + HTTPS usando el ejemplo de `control/nginx/`.
5. En Telegram usa `/codigo`.
6. En el VPS objetivo ejecuta:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/golbert19/golbert-vps/main/bootstrap.sh)
```

## Administración

```bash
sudo golbert-menu
```

## Diseño sin interferencias

Cada componente tiene su propia unidad systemd. HCR y BHTTP usan puertos TCP
distintos. BadVPN escucha únicamente en loopback por defecto. La API de control
también escucha únicamente en loopback y Nginx es quien publica HTTPS.
