package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
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

// Lee el archivo y devuelve el slice de líneas
func loadClipboard() []string {
	data, err := os.ReadFile(clipboardPath)
	if err != nil {
		log.Printf("Error leyendo clipboard: %v", err)
		return []string{}
	}
	return strings.Split(strings.TrimRight(string(data), "\n"), "\n")
}

// Guarda el slice de líneas en el archivo
func saveClipboard(content []string) {
	err := os.WriteFile(clipboardPath, []byte(strings.Join(content, "\n")), clipboardFileMode)
	if err != nil {
		log.Printf("Error guardando clipboard: %v", err)
	}
}

func getClipboard(w http.ResponseWriter, r *http.Request) {
	posStr := r.URL.Query().Get("pos")
	pos, err := strconv.Atoi(posStr)
	if err != nil || pos < 0 || pos >= maxClipboardEntries {
		//http.Error(w, "Posición inválida", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	content := loadClipboard()

	w.Header().Set("Content-Type", "text/plain")
	if pos < 0 || pos >= len(content) {
		w.Write([]byte("")) // posición vacía
	} else {
		w.Write([]byte(content[pos]))
	}
}

func setClipboard(w http.ResponseWriter, r *http.Request) {
	posStr := r.URL.Query().Get("pos")
	pos, err := strconv.Atoi(posStr)
	if err != nil || pos < 0 || pos >= maxClipboardEntries {
		//http.Error(w, "Posición inválida", http.StatusBadRequest)
		return
	}

	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		//http.Error(w, "Error leyendo body", http.StatusInternalServerError)
		return
	}
	nuevoContenido := string(bodyBytes)

	mu.Lock()
	defer mu.Unlock()

	content := loadClipboard()

	// Expandir si hace falta
	for len(content) <= pos {
		content = append(content, "")
	}

	// Actualizar posición
	content[pos] = nuevoContenido

	saveClipboard(content)

	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte("Posición actualizada correctamente"))

	// Limpiar memoria para no escribir datos viejos
	content = nil

}

func main() {
	flag.StringVar(&host, "host", "0.0.0.0", "Dirección IP o host donde escuchar")
	flag.IntVar(&port, "port", 5011, "Puerto para el servidor HTTP")
	flag.StringVar(&clipboardPath, "file", "clipboard.txt", "Ruta al archivo del clipboard")
	flag.Parse()

	log.Printf("Servidor escuchando en http://%s:%d", host, port)
	http.HandleFunc("/get", getClipboard)
	http.HandleFunc("/set", setClipboard)
	log.Fatal(http.ListenAndServe(
		fmt.Sprintf("%s:%d", host, port),
		nil,
	))
}
