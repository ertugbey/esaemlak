# EsaEmlak - Enterprise Real Estate Platform

<div align="center">

![.NET](https://img.shields.io/badge/.NET-9.0-512BD4?style=for-the-badge&logo=dotnet)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![MongoDB](https://img.shields.io/badge/MongoDB-6.0-47A248?style=for-the-badge&logo=mongodb)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-3.12-FF6600?style=for-the-badge&logo=rabbitmq)
![Redis](https://img.shields.io/badge/Redis-7.0-DC382D?style=for-the-badge&logo=redis)
![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.x-005571?style=for-the-badge&logo=elasticsearch)

**Production-ready microservices architecture for real estate listings**

</div>

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER MOBILE APP                             │
│                    (Material 3 · Provider · SignalR)                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            API GATEWAY (:5000)                          │
│              YARP Reverse Proxy · Rate Limiting · Health UI             │
└─────────────────────────────────────────────────────────────────────────┘
                    │                │                │
         ┌──────────┘                │                └──────────┐
         ▼                           ▼                           ▼
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────┐
│   AuthService   │      │   ListingsService   │      │ NotificationSvc │
│     (:5001)     │      │       (:5002)       │      │     (:5003)     │
│                 │      │                     │      │                 │
│  • JWT Auth     │      │  • CRUD Listings    │      │  • SignalR Hub  │
│  • Register     │      │  • Search (ES)      │      │  • Price Alerts │
│  • Login        │      │  • Price Drops      │      │  • WebSocket    │
└────────┬────────┘      └──────────┬──────────┘      └────────┬────────┘
         │                          │                          │
         ▼                          ▼                          │
    ┌─────────┐        ┌────────────────────┐                  │
    │ MongoDB │        │    MongoDB         │                  │
    │ (users) │        │   (listings)       │                  │
    └─────────┘        └────────────────────┘                  │
                                │                              │
                       ┌────────┴────────┐                     │
                       ▼                 ▼                     │
                 ┌──────────┐     ┌───────────┐                │
                 │  Redis   │     │Elasticsearch│               │
                 │ (cache)  │     │  (search)  │               │
                 └──────────┘     └───────────┘                │
                                                               │
                    ┌──────────────────────────────────────────┘
                    ▼
         ┌─────────────────────┐
         │      RabbitMQ       │
         │    (Event Bus)      │
         │                     │
         │ • listings.created  │
         │ • listings.updated  │
         │ • listings.pricechanged │
         └─────────────────────┘
```

---

## 📦 Microservices

| Service | Port | Responsibilities | Database |
|---------|------|------------------|----------|
| **API Gateway** | 5000 | Routing, Rate Limiting, Health Aggregation | - |
| **AuthService** | 5001 | JWT Authentication, User Management | MongoDB |
| **ListingsService** | 5002 | Listings CRUD, Search, Caching | MongoDB + ES + Redis |
| **NotificationService** | 5003 | Real-time Alerts, SignalR Hub | - |

---

## 🔄 Event-Driven Architecture

```mermaid
sequenceDiagram
    participant Client
    participant ListingsService
    participant RabbitMQ
    participant NotificationService
    participant Redis
    participant Elasticsearch

    Client->>ListingsService: PUT /listings/{id} (price change)
    ListingsService->>Elasticsearch: Update price history
    ListingsService->>Redis: Invalidate cache
    ListingsService->>RabbitMQ: Publish ListingPriceChangedEvent
    RabbitMQ->>NotificationService: Consume event
    NotificationService->>Client: SignalR push notification
```

### Event Types

| Event | Exchange | Routing Key | Payload |
|-------|----------|-------------|---------|
| `ListingCreatedEvent` | esaemlak-events | listings.created | ListingId, UserId, Baslik, Fiyat |
| `ListingUpdatedEvent` | esaemlak-events | listings.updated | ListingId, OldFiyat, NewFiyat |
| `ListingPriceChangedEvent` | esaemlak-events | listings.pricechanged | ListingId, OldPrice, NewPrice, ChangePercentage |
| `ListingViewedEvent` | esaemlak-events | listings.viewed | ListingId, ViewerIpAddress |

---

## 🗄️ Caching Strategy

### Redis Cache Configuration

```
Instance Prefix: EsaEmlak:
TTL: 15 minutes (price drops)
```

| Cache Key | Description | TTL |
|-----------|-------------|-----|
| `EsaEmlak:price_drops:10` | Top 10 discounted listings | 15 min |
| `EsaEmlak:price_drops:20` | Top 20 discounted listings | 15 min |

### Cache Flow

```
GET /api/listings/price-drops
        │
        ▼
    [Redis Check]
        │
   ┌────┴────┐
   │         │
  HIT      MISS
   │         │
   ▼         ▼
Return   Query ES
   ↑         │
   │         ▼
   │    Store in Redis
   │         │
   └─────────┘
```

---

## 🛡️ Resilience Patterns

### Polly Policies

| Policy | Configuration | Trigger |
|--------|---------------|---------|
| **Retry** | 3 attempts, exponential backoff (2s→4s→8s) | Transient HTTP errors |
| **Circuit Breaker** | Open after 5 failures, 30s duration | Sustained failures |

### Rate Limiting (API Gateway)

| Rule | Limit | Period |
|------|-------|--------|
| Global | 10 requests | 1 second |
| `/api/auth/login` | 10 requests | 1 minute |

---

## 📊 Observability

### Health Checks

**Dashboard:** `http://localhost:5000/health-ui`

| Endpoint | Checks |
|----------|--------|
| `/health` | All services aggregated |
| `/health/ready` | Database connections |
| `/health/live` | Process liveness |

### Logging (Serilog → Seq)

```
Seq URL: http://localhost:5341
Format: [HH:mm:ss LEVEL] [Service] TraceId Message
```

### Distributed Tracing (Jaeger)

```
Jaeger UI: http://localhost:16686
Services: ApiGateway, AuthService, ListingsService
```

---

## 📱 Flutter Mobile App

### State Management

| Provider | Responsibility |
|----------|----------------|
| `AuthProvider` | JWT token, user state |
| `NotificationProvider` | SignalR connection, toast notifications |
| `ServiceStatusProvider` | API health, maintenance mode |

### Key Screens

| Screen | Features |
|--------|----------|
| `HomeScreen` | Listings grid, Price Drops slider, Notification badge |
| `ListingDetailScreen` | Images, price, location, seller info |
| `MaintenanceScreen` | Gradient UI, error-specific icons |

---

## 🚀 Quick Start

```bash
# 1. Start infrastructure
docker-compose up -d mongo redis rabbitmq elasticsearch seq jaeger

# 2. Start backend services
cd backend/AuthService && dotnet run &
cd backend/ListingsService && dotnet run &
cd backend/NotificationService && dotnet run &
cd backend/ApiGateway && dotnet run &

# 3. Start Flutter app
cd flutter_app && flutter run
```

---

## 📁 Project Structure

```
esaemlak/
├── backend/
│   ├── ApiGateway/           # YARP reverse proxy + rate limiting
│   ├── AuthService/          # JWT authentication
│   ├── ListingsService/      # Core business logic
│   │   ├── Controllers/
│   │   ├── Elasticsearch/    # Search service
│   │   ├── Infrastructure/   # Polly policies
│   │   ├── Models/
│   │   ├── Repositories/
│   │   └── Services/         # Business logic + Redis cache
│   ├── NotificationService/  # SignalR hub
│   └── Shared.Events/        # Event contracts
│
├── flutter_app/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/        # State management
│   │   ├── screens/
│   │   ├── services/         # API client
│   │   └── widgets/          # Reusable components
│   └── pubspec.yaml
│
└── docker-compose.yml
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Service | Default |
|----------|---------|---------|
| `MongoDBSettings__ConnectionString` | Auth, Listings | `mongodb://localhost:27017` |
| `Redis__ConnectionString` | Listings | `localhost:6379` |
| `Elasticsearch__Uri` | Listings | `http://localhost:9200` |
| `RabbitMQ__ConnectionString` | All | `amqp://guest:guest@localhost:5672` |
| `JwtSettings__Secret` | All | (required) |

---

## 📄 License

MIT License - © 2026 EsaEmlak
