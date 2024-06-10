FROM golang:latest
ARG DOCKER_TAG
ENV VERSION=$DOCKER_TAG
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN go build -o main .
CMD ["./main"]
