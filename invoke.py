import pyperclip
import requests
import time

SERVER_URL = "http://192.168.18.15:5000"  # IP de tu servidor
last_local = ""
last_remote = ""


def invoke():
    global last_local, last_remote
    resp = requests.get(f"{SERVER_URL}/get").json()
    server_content = resp["content"]
    if server_content != last_remote:
        # Hay algo nuevo en el servidor → actualizar local
        pyperclip.copy(server_content)
        last_remote = server_content
        last_local = server_content
        print("[↓] Actualizado desde servidor:", server_content)


def set_clipboard():
    global last_local, last_remote
    current = pyperclip.paste()
    if current != last_local:
        # Se copió algo nuevo local → subirlo
        requests.post(f"{SERVER_URL}/set", json={"content": current})
        last_local = current
        last_remote = current
        print("[↑] Enviado al servidor:", current)

import sys
mode = sys.argv[1] if len(sys.argv) > 1 else "get"

if mode == "get":
    invoke()
elif mode == "set":
    set_clipboard()
