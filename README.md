# sharedClip

A simple cross-device clipboard sharing tool that combines a Go-based HTTP server with Bash scripts, allowing you to synchronize and manage multiple clipboard slots between machines. It integrates with the Linux clipboard (`xclip`) and supports automation via GNOME custom keyboard shortcuts.

## Features

- **Multi-slot Clipboard:** Store and retrieve multiple clipboard text or files(1mb max) entries (using "slots").
- **HTTP API:** Lightweight server exposes `/get?pos=N` and `/set?pos=N` endpoints for clipboard management.
- **Bash Integration:** Scripts for sending/receiving clipboard content and automation.
- **Custom Shortcuts:** Utilities to create GNOME custom keybindings for instant clipboard access.

## How It Works

- The Go server (`goserver.go`) saves clipboard slots (including file contents in base64) in a JSON file.
- The Bash script `invoke.sh` is used to send (`set`) or retrieve (`get`) clipboard data for specific slots via HTTP, using `xclip` for clipboard access.
- If you want to transfer a file, simply copy the file to your clipboard. When you run `./invoke.sh set N`, the clipboard content (which would be encoded in base64) is stored in slot N. On another machine, running `./invoke.sh get N` will retrieve the slot and restore the clipboard; if it is a file (base64), will be decoded and saved on the path defined by `FILE_COPY_PATH` in your `.env`.
- The script `run.sh` is a utility to easily start the Go server with parameters from the `.env` file.
- Shortcuts can be created to quickly send or retrieve clipboard slots.

## Requirements

- Go >= 1.18
- Bash
- `xclip`
- `curl`
- GNOME desktop (for shortcut automation)
- A `.env` file with at least:
  - `HOST` (server IP)
  - `PORT` (server port)
  - `FILE` (clipboard JSON path)
  - `MIN_SLOT`, `MAX_SLOT` (clipboard slot range)
  - `MAX_FILE_SIZE` (maximum file size in bytes for uploads, e.g., `1048576` for 1 MB)
  - `FILE_COPY_PATH` (path where received files will be saved when doing a get for files)

## Installation & Usage

### 1. Prepare Environment

Create a `.env` file with variables:
```env
HOST=127.0.0.1
PORT=5011
FILE=clipboard.json
MIN_SLOT=0
MAX_SLOT=9
MAX_FILE_SIZE=1048576   # 1 MB
FILE_COPY_PATH=/home/youruser/Downloads/sharedclip_received
```

Install required tools:
```bash
sudo apt install xclip curl golang-go
```

### 2. Run the Server

```bash
./run.sh
# or manually:
go build -o miapp goserver.go
./miapp -host=$HOST -port=$PORT -file=$FILE
```

### 3. Synchronize the Clipboard

To send or get clipboard content (text or file in base64) for a slot:
```bash
./invoke.sh set 0   # Send current clipboard to slot 0
./invoke.sh get 0   # Get slot 0 content and copy to local clipboard
```

### 4. Automate with Shortcuts (GNOME)

Generate shortcuts for all slots:
```bash
cd utils
./create_shortcuts.sh
```
This will create GNOME custom keybindings for each slot, e.g., `<Super><Alt>0` for get, `<Ctrl><Alt>0` for set.

## API

- `GET /get?pos=N` – Retrieve clipboard slot N.
- `POST /set?pos=N` (body = text or base64 file data) – Update clipboard slot N.

## File Structure

- `goserver.go` – Go HTTP server.
- `invoke.sh` – Bash script for clipboard sync.
- `run.sh` – Script to start the server.
- `required-libs` – List of dependencies.
- `utils/` – Helper scripts for shortcut automation.

## License

MIT

---

*Made by cololaborde*