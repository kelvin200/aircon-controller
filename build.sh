#!/bin/sh
# Build the server for the router (linux/arm64).
set -e
cd "$(dirname "$0")"
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ac-server ./server
echo "Built: ac-server ($(wc -c < ac-server) bytes)"