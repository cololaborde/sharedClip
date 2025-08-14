
#!/bin/bash

NUM=5
METHODS=("get" "set")

for METHOD in "${METHODS[@]}"; do
    for ((i=0; i<NUM; i++)); do
        ./create_shortcut.sh "$METHOD" "$i"
    done
done