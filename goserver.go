package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
)

const clipboardFile = "clipboard.txt"

var (
	clipboardContent string
	mu               sync.Mutex
)

// Cargar contenido desde archivo (si existe)
func loadClipboard() string {
	data, err := os.ReadFile(clipboardFile)
	if err != nil {
		return ""
	}
	return string(data)
}

// Guardar contenido en archivo
func saveClipboard(content string) {
	err := os.WriteFile(clipboardFile, []byte(content), 0644)
	if err != nil {
		log.Printf("Error guardando clipboard: %v", err)
	}
}

func getClipboard(w http.ResponseWriter, r *http.Request) {
	log.Printf("GET /get desde %s", r.RemoteAddr)
	mu.Lock()
	defer mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"content": clipboardContent,
	})
}

func setClipboard(w http.ResponseWriter, r *http.Request) {
	log.Printf("POST /set desde %s", r.RemoteAddr)
	mu.Lock()
	defer mu.Unlock()

	var data map[string]string
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	clipboardContent = data["content"]
	saveClipboard(clipboardContent)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
	})
}

func main() {
	// Cargar valor previo al iniciar
	clipboardContent = loadClipboard()

	log.Println("Servidor escuchando en http://0.0.0.0:5000")
	http.HandleFunc("/get", getClipboard)
	http.HandleFunc("/set", setClipboard)
	log.Fatal(http.ListenAndServe(":5000", nil))
}
