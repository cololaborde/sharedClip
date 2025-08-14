package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"
)

var (
	host          string
	port          int
	clipboardPath string
	mu            sync.Mutex
)

const clipboardFileMode = 0644
const maxClipboardEntries = 10

// Carga el clipboard.json como map[pos] = texto
func loadClipboard() map[string]string {
	file, err := os.ReadFile(clipboardPath)
	if err != nil {
		// Si no existe o hay error, devolvemos vacío
		return make(map[string]string)
	}

	var content map[string]string
	if err := json.Unmarshal(file, &content); err != nil {
		log.Printf("Error parseando JSON: %v", err)
		return make(map[string]string)
	}
	return content
}

// Guarda el map en clipboard.json
func saveClipboard(content map[string]string) {
	data, err := json.MarshalIndent(content, "", "  ")
	if err != nil {
		log.Printf("Error serializando JSON: %v", err)
		return
	}
	if err := os.WriteFile(clipboardPath, data, clipboardFileMode); err != nil {
		log.Printf("Error guardando clipboard: %v", err)
	}
}

// GET /get?pos=N
func getClipboard(w http.ResponseWriter, r *http.Request) {
	posStr := r.URL.Query().Get("pos")
	pos, err := strconv.Atoi(posStr)
	if err != nil || pos < 0 || pos >= maxClipboardEntries {
		return
	}

	mu.Lock()
	defer mu.Unlock()

	content := loadClipboard()
	w.Header().Set("Content-Type", "text/plain")

	if val, ok := content[posStr]; ok {
		w.Write([]byte(val))
	} else {
		w.Write([]byte("")) // vacío
	}
}

// POST /set?pos=N  (body = texto)
func setClipboard(w http.ResponseWriter, r *http.Request) {
	posStr := r.URL.Query().Get("pos")
	pos, err := strconv.Atoi(posStr)
	if err != nil || pos < 0 || pos >= maxClipboardEntries {
		return
	}

	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		return
	}
	newText := string(bodyBytes)

	mu.Lock()
	defer mu.Unlock()

	content := loadClipboard()
	content[posStr] = newText
	saveClipboard(content)

	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte("Posición actualizada correctamente"))
}

func main() {
	flag.StringVar(&host, "host", "0.0.0.0", "Dirección IP o host donde escuchar")
	flag.IntVar(&port, "port", 5011, "Puerto para el servidor HTTP")
	flag.StringVar(&clipboardPath, "file", "clipboard.json", "Ruta al archivo del clipboard JSON")
	flag.Parse()

	log.Printf("Servidor escuchando en http://%s:%d", host, port)
	http.HandleFunc("/get", getClipboard)
	http.HandleFunc("/set", setClipboard)
	log.Fatal(http.ListenAndServe(
		fmt.Sprintf("%s:%d", host, port),
		nil,
	))
}
