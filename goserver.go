package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"sync"
	"fmt"
	"io"
)

var (
	host           string
	port           int
	clipboardPath  string
	clipboardContent string
	mu             sync.Mutex
)

func loadClipboard() string {
	data, err := os.ReadFile(clipboardPath)
	if err != nil {
		log.Printf("Error leyendo clipboard: %v", err)
		return ""
	}
	return string(data)
}

func saveClipboard(content string) {
	err := os.WriteFile(clipboardPath, []byte(content), 0644)
	if err != nil {
		log.Printf("Error guardando clipboard: %v", err)
	}
}

func getClipboard(w http.ResponseWriter, r *http.Request) {
	log.Printf("GET /get desde %s", r.RemoteAddr)
	mu.Lock()
	defer mu.Unlock()

	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte(clipboardContent))
}

func setClipboard(w http.ResponseWriter, r *http.Request) {
    log.Printf("POST /set desde %s", r.RemoteAddr)

    bodyBytes, err := io.ReadAll(r.Body)
    if err != nil {
        log.Printf("Error leyendo body: %v", err)
        http.Error(w, "Error leyendo body", http.StatusInternalServerError)
        return
    }

    log.Printf("Body recibido (%d bytes)", len(bodyBytes))

    mu.Lock()
    defer mu.Unlock()

    var content string

    content = string(bodyBytes)

    clipboardContent = content
    saveClipboard(clipboardContent)

    w.Header().Set("Content-Type", "text/plain")
    w.Write([]byte("Contenido guardado correctamente"))
}

func main() {
	// Definir flags con valores por defecto
	flag.StringVar(&host, "host", "0.0.0.0", "Dirección IP o host donde escuchar")
	flag.IntVar(&port, "port", 5011, "Puerto para el servidor HTTP")
	flag.StringVar(&clipboardPath, "file", "clipboard.txt", "Ruta al archivo del clipboard")
	flag.Parse()

	clipboardContent = loadClipboard()

	log.Printf("Servidor escuchando en http://%s:%d", host, port)
	http.HandleFunc("/get", getClipboard)
	http.HandleFunc("/set", setClipboard)
	log.Fatal(http.ListenAndServe(
		host+":"+fmt.Sprint(port),
		nil,
	))
}
