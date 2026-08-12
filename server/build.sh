#!/bin/sh
# Build the server for the router (linux/arm64).
set -e
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ac-server
echo "Built: ac-server"