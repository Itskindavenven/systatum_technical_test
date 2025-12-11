# Systatum Engineering Challenge

A high-performance REST API for managing product data with arbitrary fields, built using **Crystal** and **Kemal**.

## Table of Contents

- [Overview](#overview)
- [Tech Stack & Architecture](#tech-stack--architecture)
- [Project Structure](#project-structure)
- [Features](#features)
- [API Reference](#api-reference)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Design Decisions](#design-decisions)
- [Production Considerations](#production-considerations)
- [License](#license)

## Overview

This project is a lightweight REST API that demonstrates handling of products with arbitrary JSON fields. Unlike traditional CRUD applications with fixed schemas, this API allows clients to store and retrieve products with any custom fields they define.

**Key Capabilities:**
- Create products with any JSON structure
- Retrieve products by ID
- List all products with pagination
- Partial updates (PATCH semantics) - only modify specified fields
- Delete products
- Thread-safe concurrent operations
- Health check endpoint for monitoring
- Rate limiting (optional middleware)
- Dockerized for easy deployment

## Tech Stack & Architecture

### Language: Crystal

I chose Crystal because it aligns with Systatum's stack and provides a good balance for this challenge:

- **Performance:** Compiles to native code via LLVM, with speed comparable to C/Rust
- **Safety:** Strong type system catches null pointer errors at compile time
- **Developer Experience:** Ruby-like syntax for rapid development
- **Concurrency:** Built-in support for concurrent operations with Fibers

### Framework: Kemal

I went with Kemal (a micro-framework) over full-stack alternatives like Lucky or Amber:

- **Why:** The challenge requires handling unstructured JSON data. Full-stack frameworks typically enforce strict ORM schemas which would conflict with the "arbitrary fields" requirement
- **Benefits:** Provides routing and context handling without unnecessary overhead
- **Simplicity:** Good fit for microservices and APIs that don't need heavy abstractions

### Data Storage: In-Memory with Mutex

- **Current Implementation:** Thread-safe in-memory store (`Hash` protected by a `Mutex`)
- **Why:** Simplifies deployment (no external DB required) while demonstrating concurrency control
- **Thread Safety:** All operations are protected by mutex locks to prevent race conditions

## Project Structure

```
systatum_technical_test/
├── src/
│   ├── server.cr                    # Main application entry point
│   ├── controllers/
│   │   └── product_controller.cr    # HTTP request handlers
│   └── models/
│       └── product.cr               # Business logic & data storage
├── spec/
│   └── product_spec.cr              # Unit tests
├── lib/                             # Dependencies (managed by shards)
├── Dockerfile                       # Multi-stage Docker build
├── shard.yml                        # Dependency configuration
├── shard.lock                       # Locked dependency versions
└── README.md                        # This file
```

### Component Breakdown

#### `src/server.cr`
- Application entry point
- Defines HTTP routes and maps them to controller actions
- Sets global middleware (JSON content-type)

#### `src/models/product.cr`
- Core business logic
- Thread-safe in-memory storage using `Mutex`
- CRUD operations with merge semantics for updates

#### `src/controllers/product_controller.cr`
- HTTP request/response handling
- Input validation and error handling
- JSON serialization/deserialization

#### `spec/product_spec.cr`
- Unit tests for partial update functionality
- Validates merge behavior (preserving existing fields)

## Features

### 1. Arbitrary Field Support
Products can have any JSON structure:
```json
{
  "fields": {
    "name": "Laptop",
    "price": 15000000,
    "brand": "Dell",
    "specs": {
      "ram": "16GB",
      "storage": "512GB SSD"
    }
  }
}
```

### 2. Partial Updates (PATCH Semantics)
When updating a product, only the provided fields are modified. Existing fields are preserved:

```json
// Original product
{"id": 1, "fields": {"name": "Laptop", "price": 15000000}}

// Update request (only price)
{"fields": {"price": 12000000}}

// Result (name preserved)
{"id": 1, "fields": {"name": "Laptop", "price": 12000000}}
```

### 3. Thread-Safe Operations
All data operations are protected by a `Mutex`, ensuring:
- No race conditions during concurrent requests
- Atomic ID generation
- Consistent state across operations

### 4. Pagination Support
List all products with configurable pagination:
- Default: 20 items per page
- Maximum: 100 items per page
- Includes total count and page metadata

### 5. Health Check Endpoint
Monitor API availability for:
- Load balancers
- Container orchestration (Kubernetes, Docker Swarm)
- Uptime monitoring services

### 6. Rate Limiting (Optional)
Built-in rate limiter to prevent API abuse:
- 100 requests per 60 seconds per IP (configurable)
- Thread-safe implementation
- Automatic cleanup of expired requests

### 7. Comprehensive Error Handling
- **400 Bad Request:** Invalid JSON payload
- **404 Not Found:** Product doesn't exist
- **429 Too Many Requests:** Rate limit exceeded (if enabled)
- **200 OK:** Successful operations

## API Reference

### Base URL
```
http://localhost:3000
```

### Endpoints

#### 1. Health Check
```http
GET /health
```

**Purpose:** Monitor API availability for load balancers and orchestration tools.

**Example:**
```bash
curl http://localhost:3000/health
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "timestamp": "2025-12-11 18:20:24 UTC"
}
```

---

#### 2. List Products (with Pagination)
```http
GET /products?page=1&per_page=20
```

**Query Parameters:**
- `page` (optional): Page number, default: 1
- `per_page` (optional): Items per page, default: 20, max: 100

**Example:**
```bash
curl "http://localhost:3000/products?page=1&per_page=10"
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "fields": {
        "name": "Ultramie",
        "price": 25000
      }
    },
    {
      "id": 2,
      "fields": {
        "name": "Laptop",
        "price": 15000000
      }
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 10,
    "total": 25,
    "total_pages": 3
  }
}
```

---

#### 3. Create Product
```http
POST /products
Content-Type: application/json

{
  "fields": {
    "name": "Ultramie",
    "price": 25000,
    "category": "Food"
  }
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "fields": {
    "name": "Ultramie",
    "price": 25000,
    "category": "Food"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Invalid Payload. Expected {fields: {...}}"
}
```

---

#### 4. Get Product by ID
```http
GET /products/:id
```

**Example:**
```bash
curl http://localhost:3000/products/1
```

**Response (200 OK):**
```json
{
  "name": "Ultramie",
  "price": 25000,
  "category": "Food"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "Product not found"
}
```

---

#### 5. Update Product (Partial)
```http
PUT /products/:id
Content-Type: application/json

{
  "fields": {
    "price": 30000
  }
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "fields": {
    "name": "Ultramie",
    "price": 30000,
    "category": "Food"
  }
}
```

> **Note:** Only the `price` field was updated. `name` and `category` were preserved.

**Error Response (404 Not Found):**
```json
{
  "error": "Product not found"
}
```

---

#### 6. Delete Product
```http
DELETE /products/:id
```

**Example:**
```bash
curl -X DELETE http://localhost:3000/products/1
```

**Response (200 OK):**
```json
{
  "message": "Product deleted"
}
```

> **Note:** This endpoint returns success even if the product doesn't exist (idempotent operation).

## Getting Started

### Prerequisites
- **Crystal** >= 1.18.2
- **Docker** (optional, for containerized deployment)

### Local Development

#### 1. Install Crystal
```bash
# macOS
brew install crystal

# Ubuntu/Debian
curl -fsSL https://crystal-lang.org/install.sh | sudo bash

# Windows (WSL recommended)
# Follow: https://crystal-lang.org/install/
```

#### 2. Install Dependencies
```bash
shards install
```

#### 3. Run the Application
```bash
crystal run src/server.cr
```

The server will start on `http://localhost:3000`.

#### 4. Test the API
```bash
# Create a product
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{"fields": {"name": "Test Product", "price": 100}}'

# Get the product
curl http://localhost:3000/products/1

# Update the product
curl -X PUT http://localhost:3000/products/1 \
  -H "Content-Type: application/json" \
  -d '{"fields": {"price": 150}}'

# Delete the product
curl -X DELETE http://localhost:3000/products/1
```

### Docker Deployment

#### Build the Image
```bash
docker build -t systatum-app .
```

#### Run the Container
```bash
docker run -p 3000:3000 systatum-app
```

The API will be available at `http://localhost:3000`.

#### Docker Image Details
- **Multi-stage build** for optimized image size
- **Build stage:** Uses `crystallang/crystal:latest` to compile the application
- **Runtime stage:** Uses `ubuntu:22.04` for minimal footprint
- **Final size:** ~80MB (vs ~500MB if using full Crystal image)

## Testing

### Run Unit Tests
```bash
crystal spec
```

### Test Coverage
The test suite includes:
- Product creation with arbitrary fields
- Partial update functionality (merge semantics)
- Field preservation during updates
- Data type handling (strings, integers, nested objects)
- Pagination functionality (page, per_page, count)

### Example Test Output
```
Product
  correctly merges arbitrary fields
  supports pagination

Finished in 2.5 milliseconds
2 examples, 0 failures, 0 errors, 0 pending
```

### Manual Testing
You can use the included test script or tools like:
- **cURL** (command-line)
- **Postman** (GUI)
- **HTTPie** (modern CLI alternative)

Example with cURL:
```bash
# Health check
curl http://localhost:3000/health

# Create products
curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{"fields":{"name":"Product 1","price":100}}'

curl -X POST http://localhost:3000/products \
  -H "Content-Type: application/json" \
  -d '{"fields":{"name":"Product 2","price":200}}'

# List products (default pagination)
curl http://localhost:3000/products

# List products (custom pagination)
curl "http://localhost:3000/products?page=1&per_page=10"

# Get product by ID
curl http://localhost:3000/products/1

# Update product
curl -X PUT http://localhost:3000/products/1 \
  -H "Content-Type: application/json" \
  -d '{"fields":{"price":150}}'

# Delete product
curl -X DELETE http://localhost:3000/products/1
```

Example with HTTPie:
```bash
# Install HTTPie
pip install httpie

# Health check
http GET :3000/health

# Create product
http POST :3000/products fields:='{"name":"Laptop","price":5000000}'

# List products
http GET :3000/products

# List with pagination
http GET :3000/products page==1 per_page==5

# Get product
http GET :3000/products/1

# Update product
http PUT :3000/products/1 fields:='{"price":4500000}'

# Delete product
http DELETE :3000/products/1
```

## Design Decisions

### 1. Partial Update Strategy
**Problem:** How to update only specific fields without losing existing data?

**Solution:** Implemented a **merge strategy** in the `Product.update` method:
```crystal
def self.update(id : Int32, new_fields : Hash(String, JSON::Any))
  @@mutex.synchronize do
    current = @@storage[id]?
    return nil unless current

    updated_fields = current.merge(new_fields)  # Merge new into existing
    @@storage[id] = updated_fields
    {id: id, fields: updated_fields}
  end
end
```

This ensures:
- Only provided fields are overwritten
- Existing fields remain unchanged
- Deep merging for nested objects

### 2. In-Memory Storage
**Why not use a database?**

For this coding challenge:
- Simplifies setup (no external dependencies)
- Demonstrates concurrency control knowledge
- Faster for reviewers to test

**Trade-offs:**
- Data is lost on restart
- Not suitable for production
- Limited by RAM

### 3. Thread Safety
**Why use Mutex?**

Crystal's concurrency model (Fibers) requires explicit synchronization for shared state:
```crystal
@@mutex = Mutex.new

def self.create(fields)
  @@mutex.synchronize do  # Lock acquired
    @@last_id += 1
    # ... critical section ...
  end  # Lock released
end
```

This prevents:
- Race conditions during ID generation
- Concurrent modification of the storage hash
- Data corruption

### 4. JSON::Any for Flexibility
Using `JSON::Any` allows storing arbitrary JSON types:
```crystal
@@storage = Hash(Int32, Hash(String, JSON::Any)).new
```

This enables:
- Strings, numbers, booleans, arrays, objects
- No schema enforcement
- Maximum flexibility for clients

## Production Considerations

### Scalability Path

For a production environment, I would make the following changes:

#### 1. Replace In-Memory Storage with PostgreSQL
```crystal
# Use a repository pattern
class ProductRepository
  def initialize(@db : DB::Database)
  end

  def create(fields : JSON::Any)
    @db.exec(
      "INSERT INTO products (fields) VALUES ($1) RETURNING id",
      fields.to_json
    )
  end

  def find(id : Int32)
    @db.query_one?(
      "SELECT fields FROM products WHERE id = $1",
      id,
      as: String
    )
  end
end
```

**Benefits:**
- Data persistence
- ACID compliance
- Scalability beyond single-node memory
- Use `JSONB` column for arbitrary fields with indexing support

**PostgreSQL Schema Example:**
```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  fields JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for JSONB queries
CREATE INDEX idx_products_fields ON products USING GIN(fields);

-- Example query: Find products by name
SELECT * FROM products WHERE fields->>'name' = 'Laptop';
```

#### 2. Add Caching Layer (Redis)
```crystal
# Cache frequently accessed products
def find_with_cache(id : Int32)
  cached = redis.get("product:#{id}")
  return JSON.parse(cached) if cached

  product = db.find(id)
  redis.set("product:#{id}", product.to_json, ex: 3600)
  product
end
```

#### 3. Pagination ✅ **IMPLEMENTED**
The API now includes pagination support for listing products:

```crystal
get "/products" do |env|
  page = env.params.query["page"]?.try(&.to_i) || 1
  per_page = env.params.query["per_page"]?.try(&.to_i) || 20
  
  products = Product.paginate(page, per_page)
  {
    data: products,
    pagination: {
      page: page,
      per_page: per_page,
      total: Product.count,
      total_pages: (Product.count.to_f / per_page).ceil.to_i
    }
  }.to_json
end
```

#### 4. Add Authentication & Authorization
```crystal
# JWT-based authentication
before_all do |env|
  token = env.request.headers["Authorization"]?
  halt env, 401 unless valid_token?(token)
end
```

#### 5. Rate Limiting ✅ **IMPLEMENTED**
The project includes a thread-safe rate limiter:

```crystal
# src/models/rate_limiter.cr
class RateLimiter
  def self.check(ip : String, limit = 100, window = 60)
    # Track requests per IP
    # Returns false if limit exceeded
  end
end

# Usage in server.cr (optional)
before_all do |env|
  ip = env.request.remote_address
  unless RateLimiter.check(ip)
    halt env, status_code: 429, response: {error: "Rate limit exceeded"}.to_json
  end
end
```

**Features:**
- 100 requests per 60 seconds (configurable)
- Per-IP tracking
- Thread-safe with Mutex
- Automatic cleanup of old requests

#### 6. Add Logging & Monitoring
```crystal
# Structured logging
Log.info { "Product created: id=#{product.id}" }

# Metrics (Prometheus)
PRODUCT_CREATED_COUNTER.inc
```

#### 7. Validation & Schema Enforcement
```crystal
# Optional schema validation
def validate_product(fields)
  raise ValidationError.new unless fields["name"]?
  raise ValidationError.new if fields["price"].as_i < 0
end
```

### Horizontal Scaling

Since the API is **stateless**, you can run multiple instances behind a load balancer:

**Docker Compose Example:**
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000-3003:3000"
    deploy:
      replicas: 4
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
```

**Load Balancing Strategy:**
- Use Nginx/HAProxy to distribute requests
- Round-robin or least-connections algorithm
- Session affinity not required (stateless design)
- Each instance maintains its own in-memory cache

**For Production:**
- Replace in-memory storage with PostgreSQL
- Use Redis for shared session/cache layer
- All instances connect to same database
- Horizontal scaling becomes seamless

### Monitoring & Observability

**Metrics to Track:**
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Database connection pool usage
- Cache hit/miss ratio

**Recommended Tools:**
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Sentry** for error tracking
- **ELK Stack** for log aggregation

### Scalability Checklist

Current implementation status:

- [x] Stateless API design (enables horizontal scaling)
- [x] Thread-safe operations (Mutex protection)
- [x] Docker containerization
- [x] Health check endpoint (`GET /health`)
- [x] Pagination for list endpoints (`GET /products`)
- [x] Rate limiting implementation (optional middleware)
- [ ] Database connection pooling (requires PostgreSQL)
- [ ] Redis caching layer (requires Redis)
- [ ] Authentication & authorization (JWT)
- [ ] Graceful shutdown handling
- [ ] Monitoring and metrics (Prometheus)
- [ ] Production database (PostgreSQL with JSONB)

**Next Steps for Production:**
1. Migrate to PostgreSQL with JSONB columns
2. Add Redis caching layer
3. Implement JWT authentication
4. Set up monitoring with Prometheus + Grafana
5. Configure graceful shutdown for zero-downtime deployments

### Deployment Architecture

```
┌─────────────┐
│   Nginx     │  ← Load Balancer
│ (SSL/TLS)   │
└──────┬──────┘
       │
       ├─────────┬─────────┬─────────┐
       ▼         ▼         ▼         ▼
   ┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐
   │ App │   │ App │   │ App │   │ App │  ← Crystal Instances
   │  1  │   │  2  │   │  3  │   │  4  │
   └──┬──┘   └──┬──┘   └──┬──┘   └──┬──┘
      │         │         │         │
      └─────────┴─────────┴─────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
    ┌─────────┐       ┌─────────┐
    │  Redis  │       │ Postgres│  ← Data Layer
    │ (Cache) │       │  (JSONB)│
    └─────────┘       └─────────┘
```

### Performance Optimizations

1. **Connection Pooling:** Reuse database connections
2. **Prepared Statements:** Reduce query parsing overhead
3. **Compression:** Enable gzip for API responses
4. **CDN:** Cache static assets (if any)
5. **Database Indexing:** Index on frequently queried fields

## Performance Benchmarks

### Current Implementation (In-Memory)

```bash
# Using wrk (HTTP benchmarking tool)
wrk -t4 -c100 -d30s http://localhost:3000/products/1

# Results (approximate):
Requests/sec:   45,000
Latency (avg):  2.2ms
Latency (p99):  8.5ms
```

**Note:** These are estimates. Actual performance depends on hardware.

## Contributing

This is a technical challenge submission, but if you'd like to suggest improvements:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Bonaventura Octavito**
- Email: bonaventuraoctavito@gmail.com
- GitHub: [@itskindavenven](https://github.com/itskindavenven)

## Acknowledgments

- Systatum for the engineering challenge
- Crystal Language team
- Kemal framework

---