#!/bin/bash

echo "Building binary"
GOOS=linux GOARCH=amd64 go build -o main main.go

echo "Create deployment package"
zip deployment.zip main

echo "Cleanup"
rm main
