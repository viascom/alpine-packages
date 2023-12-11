package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"github.com/sirupsen/logrus"
)

var log = logrus.New()

type PackageRequest struct {
	PackageNames []string `json:"package_names"`
}

type PackageResponse struct {
	ReceivedPackages []string `json:"received_packages"`
}

var (
	username = flag.String("username", "a-username", "Username for basic authentication")
	password = flag.String("password", "a-password", "Password for basic authentication")
	port     = flag.String("port", "8080", "Port on which the server will run")
)

func BasicAuthMiddleware(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, pass, ok := r.BasicAuth()
		if !ok || user != *username || pass != *password {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		handler(w, r)
	}
}

func RunScript(packageNames []string) {
	logFile, err := os.OpenFile("/var/log/alpine-packages/packages.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.WithFields(logrus.Fields{
			"error": err,
		}).Error("Failed to open log file")
		return
	}

	defer func() {
		if closeErr := logFile.Close(); closeErr != nil {
			log.WithFields(logrus.Fields{
				"error": closeErr,
			}).Error("Failed to close log file")
		}
	}()

	cmd := exec.Command("/bin/bash", "/home/exie/archive.sh")
	cmd.Args = append(cmd.Args, packageNames...)
	cmd.Stdout = logFile
	cmd.Stderr = logFile

	if err := cmd.Run(); err != nil {
		log.WithFields(logrus.Fields{
			"error":   err,
			"command": "archive.sh",
		}).Error("Error running script")
	}
}

func PackagesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Content-Type must be application/json", http.StatusUnsupportedMediaType)
		return
	}

	var req PackageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	go RunScript(req.PackageNames)

	resp := PackageResponse{ReceivedPackages: req.PackageNames}
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		http.Error(w, "Error marshaling response", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if _, err := w.Write(jsonResp); err != nil {
		log.WithFields(logrus.Fields{
			"error":   err,
			"package": req.PackageNames,
		}).Error("Error writing JSON response")
	}
}

func HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	if _, err := fmt.Fprint(w, "OK"); err != nil {
		log.WithFields(logrus.Fields{
			"error": err,
		}).Error("Error writing health check response")
	}
}

func main() {
	file, err := os.OpenFile("/var/log/alpine-packages/alpine-packages-api.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil {
		log.Out = file
	} else {
		log.Info("Failed to log to file, using default stderr")
	}
	log.Info("This is some information")

	defer file.Close()

	flag.Parse()

	if *username == "" || *password == "" || *port == "" {
		log.Fatal("Username, password and port must be provided.")
	}

	server := &http.Server{Addr: fmt.Sprintf(":%s", *port), Handler: nil}

	http.HandleFunc("/archive", BasicAuthMiddleware(PackagesHandler))
	http.HandleFunc("/health", BasicAuthMiddleware(HealthCheckHandler))

	go func() {
		fmt.Printf("Server is running on port %s...\n", *port)
		if err := server.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("HTTP server ListenAndServe: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	<-stop

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server Shutdown Failed:%+v", err)
	}

	log.Println("Server gracefully stopped")
}
