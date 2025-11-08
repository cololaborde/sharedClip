#!/bin/bash

export $(grep -v '^#' "$HOME/Documents/sharedClip/.env" | xargs)

SERVER_URL="http://$HOST:$PORT"
MODE="${1:-get}"  # Modo por defecto: get
LAST_LOCAL=""
LAST_REMOTE=""
POS="${2:-0}"

detect_clipboard_tool() {
    if command -v wl-copy &>/dev/null && command -v wl-paste &>/dev/null; then
        CLIP_MODE="wayland"
    elif command -v xclip &>/dev/null; then
        CLIP_MODE="xclip"
    elif command -v xsel &>/dev/null; then
        CLIP_MODE="xsel"
    else
        echo "[!] No se encontró ninguna herramienta de portapapeles (instalá xclip, xsel o wl-clipboard)"
        exit 1
    fi
}

clipboard_get() {
    case "$CLIP_MODE" in
        wayland) wl-paste ;;
        xclip)   xclip -selection clipboard -o ;;
        xsel)    xsel --clipboard --output ;;
    esac
}

clipboard_set() {
    case "$CLIP_MODE" in
        wayland) wl-copy ;;
        xclip)   xclip -selection clipboard ;;
        xsel)    xsel --clipboard --input ;;
    esac
}

clipboard_get_uri() {
    case "$CLIP_MODE" in
        wayland) wl-paste --type text/uri-list 2>/dev/null ;;
        xclip)   xclip -selection clipboard -t text/uri-list -o 2>/dev/null ;;
        xsel)    xsel --clipboard --output 2>/dev/null ;;
    esac
}

detect_clipboard_tool

get_clipboard() {
    SERVER_CONTENT=$(curl -s "$SERVER_URL/get?pos=$POS")

    if [[ "$SERVER_CONTENT" != "$LAST_REMOTE" ]]; then
        if [[ "$SERVER_CONTENT" == file://* ]]; then
            payload=$(echo "$SERVER_CONTENT" | sed -e 's|^file://||' | tr -d '\n\r ')
            filename=$(echo "$payload" | cut -d"|" -f1)
            b64_content=$(echo "$payload" | cut -d"|" -f2-)

            if echo "$b64_content" | base64 -d > "$FILE_COPY_PATH$filename" 2>/dev/null; then
                echo "[↓] Archivo guardado en $FILE_COPY_PATH$filename"
            else
                echo "[!] Error al decodificar o guardar el archivo."
            fi
        else
            echo "$SERVER_CONTENT" | clipboard_set
        fi

        LAST_REMOTE="$SERVER_CONTENT"
        LAST_LOCAL="$SERVER_CONTENT"
    fi
}

set_clipboard() {
    if CURRENT=$(clipboard_get_uri); then
        echo "is file(s)"
        path=$(echo "$CURRENT" | sed -e 's|^file://||' | tr -d '\n\r')
        path=$(printf '%b' "${path//%/\\x}")

        file_size=$(stat -c%s "$path")
        if [[ "$file_size" -gt $MAX_FILE_SIZE ]]; then
            echo "[!] El archivo es demasiado grande para manejarlo. Tamaño máximo 1 MB"
            return
        fi
        filename=$(basename "$path")
        b64_encode=$(base64 -w0 "$path")

        CURRENT="file://$filename|$b64_encode"
    else
        echo "is text"
        CURRENT=$(clipboard_get 2>/dev/null)
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
