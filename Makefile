compile:
	GOOS=linux GOARCH=amd64 go build -o main main.go

compress:
	zip deployment.zip main
	rm main

release: compile \
	compress
