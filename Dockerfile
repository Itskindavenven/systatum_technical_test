# Build stage
FROM crystallang/crystal:latest as builder
WORKDIR /app
COPY . .
RUN shards install
RUN crystal build src/server.cr --release

# Run stage (Small image size)
FROM ubuntu:22.04
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 3000
CMD ["./server"]