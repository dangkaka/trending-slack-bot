compile:
	GOOS=linux GOARCH=amd64 go build -o main main.go

compress:
	zip release.zip main
	rm main

release: compile \
	compress
