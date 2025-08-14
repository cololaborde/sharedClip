#!/bin/bash

# =======================
# CONFIG
# =======================
NOMBRE="$1 $2"
COMANDO="$HOME/Documentos/sharedClip/invoke.sh $1 $2"
if [[ "$1" == "get" ]]; then
    ATAJO="<Super><Alt>$2"
elif [[ "$1" == "set" ]]; then
    ATAJO="<Ctrl><Alt>$2"
fi
KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# =======================
# FUNCIÓN SEGURA PARA AGREGAR
# =======================
add_binding() {
    local path="$1"

    # Obtener lista actual
    local existing
    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    # Convertir "@as []" a lista vacía
    if [[ "$existing" == "@as []" ]]; then
        new_list="['$path']"
    else
        # Quitar corchetes iniciales y finales
        existing="${existing:1:-1}"
        # Evitar duplicados
        if [[ "$existing" == *"'$path'"* ]]; then
            echo "⚠️ Ya existe el binding en la lista."
            return
        fi
        new_list="[$existing, '$path']"
    fi

    # Guardar lista actualizada
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
}

# =======================
# CREAR NUEVO BINDING
# =======================
NEW_BINDING="$KEY_PATH/custom$(date +%s)/"
add_binding "$NEW_BINDING"

# Configurar datos del binding
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_BINDING" name "$NOMBRE"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_BINDING" command "$COMANDO"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$NEW_BINDING" binding "$ATAJO"

echo "✅ Atajo '$NOMBRE' creado con $ATAJO → $COMANDO"
