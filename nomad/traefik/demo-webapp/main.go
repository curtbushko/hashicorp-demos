package main

import (
	"fmt"
	"net/http"
	"os"
)

var host string = os.Getenv("NODE_IP")
var port string = os.Getenv("PORT")
var version string = os.Getenv("VERSION")

func giveIntro(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome! You are on node %s:%s, running version: %s\n", host, port, version)
}

func main() {
	mux := http.NewServeMux()
	server := &http.Server{
		Addr:    fmt.Sprintf("0.0.0.0:%v", port),
		Handler: mux,
	}
	mux.HandleFunc("/", giveIntro)
	server.ListenAndServe()
}
