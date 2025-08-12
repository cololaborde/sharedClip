#!/bin/bash

SERVER_URL="http://192.168.18.20:5000"  # IP de tu servidor
MODE="${1:-get}"  # Modo por defecto: get
LAST_LOCAL=""
LAST_REMOTE=""

get_clipboard() {
    SERVER_CONTENT=$(curl -s "$SERVER_URL/get" | jq -r '.content')

    if [[ "$SERVER_CONTENT" != "$LAST_REMOTE" ]]; then
        echo "$SERVER_CONTENT" | xclip -selection clipboard
        LAST_REMOTE="$SERVER_CONTENT"
        LAST_LOCAL="$SERVER_CONTENT"
        echo "[↓] Actualizado desde servidor: $SERVER_CONTENT"
    fi
}

set_clipboard() {
    CURRENT=$(xclip -selection clipboard -o)
    if [[ "$CURRENT" != "$LAST_LOCAL" ]]; then
        curl -s -X POST "$SERVER_URL/set" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$CURRENT\"}" > /dev/null
        LAST_LOCAL="$CURRENT"
        LAST_REMOTE="$CURRENT"
        echo "[↑] Enviado al servidor: $CURRENT"
    fi
}

if [[ "$MODE" == "get" ]]; then
    get_clipboard
elif [[ "$MODE" == "set" ]]; then
    set_clipboard
else
    echo "Uso: $0 [get|set]"
fi
