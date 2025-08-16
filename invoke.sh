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
            payload=$(echo "$SERVER_CONTENT" | sed -e 's|^file://||' | tr -d '\n\r ')
            filename=$(echo "$payload" | cut -d"|" -f1)
            b64_content=$(echo "$payload" | cut -d"|" -f2-)

            if echo "$b64_content" | base64 -d > "$FILE_SAVE_PATH$filename" 2>/dev/null; then
                echo "[↓] Archivo guardado en $FILE_SAVE_PATH$filename"
            else
                echo "[!] Error al decodificar o guardar el archivo."
            fi
        else
            echo "$SERVER_CONTENT" | xclip -selection clipboard
        fi

        LAST_REMOTE="$SERVER_CONTENT"
        LAST_LOCAL="$SERVER_CONTENT"
    fi
}

set_clipboard() {
    if CURRENT=$(xclip -selection clipboard -t text/uri-list -o 2>/dev/null); then
        echo "is file(s)"
        path=$(echo "$CURRENT" | sed -e 's|^file://||' | tr -d '\n\r')

        # check file size
        file_size=$(stat -c%s "$path")
        if [[ "$file_size" -gt $MAX_FILE_SIZE ]]; then
            echo "[!] El archivo es demasiado grande para manejarlo. Tamaño maximo 1 MB"
            return
        fi
        filename=$(basename "$path")
        b64_encode=$(base64 -w0 "$path")

        # se guarda nombre y encoding
        CURRENT="file://$filename|$b64_encode"
    else
        echo "is text"
        CURRENT=$(xclip -selection clipboard -o 2>/dev/null)
    fi

    if [[ "$CURRENT" != "$LAST_LOCAL" ]]; then
        echo -n "$CURRENT" | curl -s -X POST "$SERVER_URL/set?pos=$POS" \
            -H "Content-Type: text/plain" \
            --data-binary @- > /dev/null
        LAST_LOCAL="$CURRENT"
        LAST_REMOTE="$CURRENT"
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
