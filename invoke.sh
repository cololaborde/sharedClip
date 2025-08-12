current_path=$(pwd)

#!/bin/bash
exec >> "$current_path/log.txt" 2>&1

if [ -z "$1" ]; then
  echo "No argument supplied"
  exit 1
fi

#check if venv exist
if [ ! -d "$current_path/venv" ]; then
  python3 -m venv "$current_path/venv"
  source "$current_path/venv/bin/activate"
  pip install -r "$current_path/requirements.txt"
  deactivate
fi

source "$current_path/venv/bin/activate"
"$current_path/venv/bin/python" "$current_path/invoke.py" "$1"
deactivate
exit 0
