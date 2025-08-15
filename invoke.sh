#!/bin/bash

export $(grep -v '^#' $HOME/Documentos/sharedClip/.env | xargs)

# Required ENV variables: HOST, PORT, MIN_SLOT, MAX_SLOT

SERVER_URL="http://$HOST:$PORT"
MODE="${1:-get}"  # Modo por defecto: get
LAST_LOCAL=""
LAST_REMOTE=""
POS="${2:-0}"

get_clipboard() {
    SERVER_CONTENT=$(curl -s "$SERVER_URL/get?pos=$POS")

    if [[ "$SERVER_CONTENT" != "$LAST_REMOTE" ]]; then
        if [[ "$SERVER_CONTENT" == file://* ]]; then
            echo "$SERVER_CONTENT" | xclip -selection clipboard -t "text/uri-list"
        elif [[ "$SERVER_CONTENT" == * ]]; then
            echo "$SERVER_CONTENT" | xclip -selection clipboard -t "text/plain"
        fi
        LAST_REMOTE="$SERVER_CONTENT"
        LAST_LOCAL="$SERVER_CONTENT"
        echo "[↓] Actualizado desde servidor: $SERVER_CONTENT"
    fi
}

set_clipboard() {
    if CURRENT=$(xclip -selection clipboard -t text/uri-list -o 2>/dev/null); then
        echo "is file(s)"
    else
        echo "is text"
        CURRENT=$(xclip -selection clipboard -o 2>/dev/null)
    fi
    echo "$CURRENT"
    if [[ "$CURRENT" != "$LAST_LOCAL" ]]; then
        curl -s -X POST "$SERVER_URL/set?pos=$POS" \
            -H "Content-Type: text/plain" \
            -d "$CURRENT" > /dev/null
        LAST_LOCAL="$CURRENT"
        LAST_REMOTE="$CURRENT"
        echo "[↑] Enviado al servidor: $CURRENT"
    fi
}

if [[ "$POS" -lt "$MIN_SLOT" || "$POS" -gt "$MAX_SLOT" ]]; then
    echo "Posición inválida. Debe estar entre $MIN_SLOT y $MAX_SLOT."
    exit 1
fi
if [[ "$MODE" == "get" ]]; then
    get_clipboard
elif [[ "$MODE" == "set" ]]; then
    set_clipboard
else
    echo "Uso: $0 [get|set] [pos[$MIN_SLOT..$MAX_SLOT]]"
fi
