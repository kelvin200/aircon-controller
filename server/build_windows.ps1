# Build the server for the Windows dev host (windows/amd64).
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$env:GOOS = "windows"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"

go build -o ac-server.exe .
Write-Host "Built: server\ac-server.exe"