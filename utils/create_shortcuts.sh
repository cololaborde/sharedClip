
#!/bin/bash

export $(grep -v '^#' /home/colo/Documentos/sharedClip/.env | xargs)

# Required ENV variables: MIN_SLOT, MAX_SLOT

METHODS=("get" "set")

for METHOD in "${METHODS[@]}"; do
    for ((i=MIN_SLOT; i<=MAX_SLOT; i++)); do
        ./create_shortcut.sh "$METHOD" "$i"
    done
done