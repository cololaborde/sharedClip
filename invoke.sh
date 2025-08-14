#!/bin/bash

export $(grep -v '^#' .env | xargs)

SERVER_URL="http://$HOST:$PORT"
MODE="${1:-get}"  # Modo por defecto: get
LAST_LOCAL=""
LAST_REMOTE=""

POS="${2:-0}"

get_clipboard() {
    SERVER_CONTENT=$(curl -s "$SERVER_URL/get?pos=$POS")

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
        curl -s -X POST "$SERVER_URL/set?pos=$POS" \
            -H "Content-Type: text/plain" \
            -d "$CURRENT" > /dev/null
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
