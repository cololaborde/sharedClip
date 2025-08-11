#!/bin/bash
exec >> /home/colo/Documentos/sharedClip/log.txt 2>&1

if [ -z "$1" ]; then
  echo "No argument supplied"
  exit 1
fi

source /home/colo/Documentos/sharedClip/venv/bin/activate
/home/colo/Documentos/sharedClip/venv/bin/python /home/colo/Documentos/sharedClip/invoke.py "$1"
deactivate
exit 0
