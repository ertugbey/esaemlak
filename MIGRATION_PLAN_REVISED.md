# Emlaktan Migration: Flutter + .NET Microservices - REVISED PLAN

## 🎯 Executive Summary

This **revised** plan addresses critical architectural gaps identified in senior developer review:

✅ **Added: Shorebird** - True OTA code updates (not just config)  
✅ **Added: RabbitMQ** - Event-driven architecture for loose coupling  
✅ **Added: Elasticsearch** - Production-grade faceted search  
✅ **Clarified: Database boundaries** - Logical separation within MongoDB

---

## Critical Improvements from Review

### 1. Shorebird Integration (OTA Code Updates)

**Problem Identified**: Firebase Remote Config only changes parameters, NOT code logic.

**Solution**: [Shorebird](https://shorebird.dev/) - Flutter's official code push solution
- Fix bugs without Play Store submission
- Deploy hotfixes in minutes  
- Update business logic remotely
- Rollback capability

**Timeline Impact**: +1 week for Shorebird setup and CI/CD integration

---

### 2. RabbitMQ Event Bus (Loosely Coupled Services)

**Problem Identified**: All services sharing same MongoDB creates "Distributed Monolith"

**Solution**: Event-Driven Architecture with RabbitMQ
- Services publish events (UserRegistered, ListingCreated, PaymentCompleted)
- Other services subscribe to events they care about
- NO direct cross-service database queries
- Enables independent scaling and deployment

**Example Flow**:
```
1. PaymentService → Publishes "PremiumPurchased" event to RabbitMQ
2. RabbitMQ → Broadcasts to subscribers
3. NotificationService → Sends "Thank you" email
4. AnalyticsService → Updates dashboard stats
5. AuthService → Upgrades user role
```

**Timeline Impact**: +1 week for RabbitMQ integration and event modeling

---

### 3. Elasticsearch (Advanced Search)

**Problem Identified**: MongoDB struggles with complex faceted searches

**Solution**: Elasticsearch for listing searches
- Handles "Antalya + 3+1 + Havuzlu + 5M altı" style queries efficiently
- Full-text search in descriptions
- Geo-spatial + filters combined
- near-instant response times

**Data Flow**:
```
Write: MongoDB (source of truth) → RabbitMQ event → Elasticsearch (indexed copy)
Read: Search queries → Elasticsearch only
```

**Timeline Impact**: +1 week for Elasticsearch setup and indexing strategy

---

## Revised Architecture Diagram

```mermaid
graph TB
    subgraph "Flutter App"
        FLUTTER[Flutter UI]
        SHOREBIRD[Shorebird OTA]
        REMOTE_CONFIG[Firebase Remote Config]
    end
    
    subgraph "Backend Services"
        GATEWAY[API Gateway<br/>Ocelot]
        AUTH[AuthService]
        LISTING[ListingsService]
        PAYMENT[PaymentService]
        MESSAGING[MessagingService<br/>SignalR]
        NOTIFICATION[NotificationService]
        ANALYTICS[AnalyticsService]
    end
    
    subgraph "Event & Data Layer"
        RABBITMQ{{RabbitMQ<br/>Event Bus}}
        MONGODB[(MongoDB Atlas)]
        ELASTICSEARCH[(Elasticsearch)]
        REDIS[Redis]
    end
    
    subgraph "External"
        FIREBASE[Firebase]
        SHOREBIRD_CLOUD[Shorebird Cloud]
        IYZICO[iyzico]
    end
    
    FLUTTER <--> GATEWAY
    SHOREBIRD_CLOUD -.Patches.-> SHOREBIRD
    REMOTE_CONFIG <--> FIREBASE
    
    GATEWAY --> AUTH
    GATEWAY --> LISTING
    GATEWAY --> PAYMENT
    GATEWAY --> MESSAGING
    
    AUTH --> MONGODB
    LISTING --> MONGODB
    PAYMENT --> MONGODB
    MESSAGING --> MONGODB
    
    AUTH -.UserRegistered.-> RABBITMQ
    LISTING -.ListingCreated.-> RABBITMQ
    LISTING -.ListingDeleted.-> RABBITMQ
    PAYMENT -.PaymentCompleted.-> RABBITMQ
    
    RABBITMQ -.-> NOTIFICATION
    RABBITMQ -.-> ANALYTICS
    
    LISTING --> ELASTICSEARCH
    LISTING <-- Search --> ELASTICSEARCH
    
    MESSAGING --> REDIS
    NOTIFICATION --> FIREBASE
    PAYMENT --> IYZICO
```

---

## Technology Stack (Finalized)

| Layer | Technology | Justification |
|-------|-----------|---------------|
| **Mobile** | Flutter 3.x | Cross-platform, high performance |
| **OTA Updates** | Shorebird | Flutter's official code push |
| **Remote Config** | Firebase Remote Config | Feature flags, theme changes |
| **Backend** | .NET 8.0 | Modern, performant, async-first |
| **Database** | MongoDB Atlas | Existing cluster, flexible schema |
| **Search** | Elasticsearch 8.x | Production-grade search |
| **Event Bus** | RabbitMQ 3.x | Reliable message broker |
| **Real-time** | SignalR + Redis | Scalable WebSocket |
| **API Gateway** | Ocelot | .NET-native gateway |
| **Payments** | i

yzico | Turkish market leader |
| **State Management** | Riverpod | Recommended for Flutter |

---

## Microservices Detailed Design

### 1. AuthService (.NET 8)

**Responsibilities**:
- JWT auth, 2FA, password reset
- User profile management
- Role-based access control

**Events Published**:
- `UserRegistered` → Triggers welcome email
- `UserUpgradedToPremium` → Updates analytics

**MongoDB Collections**: `emlakcis` collection only

**NuGet Packages**:
```xml
<PackageReference Include="MongoDB.Driver" Version="2.24.0" />
<PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
<PackageReference Include="RabbitMQ.Client" Version="6.6.0" />
```

---

### 2. ListingsService (.NET 8)

**Responsibilities**:
- CRUD operations on listings
- Image upload/compression
- GeoJSON spatial queries (MongoDB)
- **Elasticsearch indexing**

**Events Published**:
- `ListingCreated` → Index in Elasticsearch, notify watchers
- `ListingPriceChanged` → Trigger price alerts
- `ListingDeleted` → Remove from Elasticsearch, favorites

**Events Consumed**:
- `UserDeleted` → Delete user's listings

**MongoDB Collections**: `ilans` collection

**Search Strategy**:
```csharp
// Write to MongoDB
await _mongoListings.InsertOneAsync(listing);

// Publish event to RabbitMQ
await _eventBus.PublishAsync(new ListingCreatedEvent {
    ListingId = listing.Id,
    // ... listing data
});

// Elasticsearch indexer (separate consumer) listens to RabbitMQ
// and indexes the listing asynchronously
```

**Advanced Search Flow**:
```
User searches → ListingsService → Elasticsearch (query) → Returns IDs
→ Fetch full documents from MongoDB by IDs
```

---

### 3. PaymentService (.NET 8)

**Responsibilities**:
- iyzico payment processing
- Premium subscription management
- **MongoDB transactions** (critical for financial consistency)

**Events Published**:
- `PaymentCompleted` → Activate premium
- `PaymentFailed` → Log and notify

**MongoDB Transactions Example**:
```csharp
using (var session = await _mongoClient.StartSessionAsync())
{
    session.StartTransaction();
    try
    {
        // 1. Insert payment record
        await _payments.InsertOneAsync(session, payment);
        
        // 2. Update user premium status
        await _users.UpdateOneAsync(session, 
            filter, 
            Builders<User>.Update.Set(u => u.IsPremium, true));
        
        await session.CommitTransactionAsync();
        
        // 3. Publish event AFTER commit
        await _eventBus.PublishAsync(new PaymentCompletedEvent { ... });
    }
    catch
    {
        await session.AbortTransactionAsync();
        throw;
    }
}
```

⚠️ **Critical**: Always use MongoDB sessions for financial operations to ensure ACID compliance.

---

### 4. MessagingService (SignalR + .NET 8)

**Responsibilities**:
- Real-time chat via SignalR
- Message persistence
- Online status tracking

**Scaling with Redis**:
```csharp
// Program.cs
builder.Services.AddSignalR()
    .AddStackExchangeRedis("redis:6379", options => {
        options.Configuration.ChannelPrefix = "SignalR";
    });
```

Multiple `MessagingService` instances can share state via Redis backplane.

---

### 5. NotificationService (.NET 8)

**Responsibilities**:
- Push notifications (Firebase)
- SMS (Twilio)
- Email (SendGrid or SMTP)

**Events Consumed**:
- `UserRegistered` → Send welcome email
- `ListingCreated` → Notify followers
- `PaymentCompleted` → Send receipt
- `PriceAlertTriggered` → Notify user

**Implementation**:
```csharp
public class NotificationService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var consumer = new EventingBasicConsumer(_channel);
        consumer.Received += async (model, ea) =>
        {
            var eventType = ea.RoutingKey;
            var body = Encoding.UTF8.GetString(ea.Body.ToArray());
            
            switch (eventType)
            {
                case "user.registered":
                    await SendWelcomeEmail(body);
                    break;
                case "payment.completed":
                    await SendPushNotification(body);
                    break;
            }
        };
        
        _channel.BasicConsume(queue: "notifications-queue", consumer: consumer);
    }
}
```

---

## RabbitMQ Event Design

### Exchange & Queue Architecture

```
Exchange: emlaktan.events (Topic Exchange)

Queues:
- notifications-queue → Binds to: user.*, listing.*, payment.*
- analytics-queue → Binds to: #
- search-index-queue → Binds to: listing.*
```

### Event Schema Example

```json
{
  "eventId": "uuid",
  "eventType": "listing.created",
  "timestamp": "2025-12-31T12:00:00Z",
  "aggregateId": "listing-id-123",
  "data": {
    "listingId": "123",
    "emlakciId": "456",
    "baslik": "3+1 Lüks Daire",
    "fiyat": 5000000,
    "konum": {
      "type": "Point",
      "coordinates": [30.7133, 36.8969]
    }
  },
  "metadata": {
    "userId": "456",
    "correlationId": "request-789"
  }
}
```

### Dead Letter Queue (DLQ)

Failed events go to `emlaktan.events.dlq` for manual inspection and replay.

---

## Elasticsearch Setup

### Index Mapping for Listings

```json
{
  "mappings": {
    "properties": {
      "listingId": { "type": "keyword" },
      "baslik": { 
        "type": "text",
        "analyzer": "turkish"
      },
      "aciklama": { 
        "type": "text",
        "analyzer": "turkish"
      },
      "fiyat": { "type": "double" },
      "metrekare": { "type": "double" },
      "emlakTipi": { "type": "keyword" },
      "islemTipi": { "type": "keyword" },
      "odaSayisi": { "type": "keyword" },
      "konum": { "type": "geo_point" },
      "createdAt": { "type": "date" }
    }
  }
}
```

### Faceted Search Query Example

```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "aciklama": "deniz manzaralı" } }
      ],
      "filter": [
        { "term": { "emlakTipi": "ev" } },
        { "term": { "islemTipi": "satılık" } },
        { "range": { "fiyat": { "lte": 5000000 } } },
        { "geo_distance": {
            "distance": "5km",
            "konum": { "lat": 36.8969, "lon": 30.7133 }
          }
        }
      ]
    }
  },
  "aggs": {
    "by_odaSayisi": {
      "terms": { "field": "odaSayisi" }
    },
    "avg_fiyat": {
      "avg": { "field": "fiyat" }
    }
  }
}
```

### Sync Strategy

**Option 1: Event-Driven (Recommended)**
```
MongoDB Write → RabbitMQ → Elasticsearch Indexer Service
```

**Option 2: Change Streams**
```
MongoDB Change Stream → Detect insert/update/delete → Update Elasticsearch
```

---

## Flutter App: Shorebird Integration

### Installation

```bash
# Install Shorebird CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Initialize in Flutter project
shorebird init

# Create release
shorebird release android

# Later, push patch (no store update!)
shorebird patch android
```

### pubspec.yaml (Updated)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Network
  dio: ^5.4.0
  signalr_netcore: ^1.3.0
  
  # Remote Config
  firebase_core: ^2.24.0
  firebase_remote_config: ^4.3.0
  firebase_messaging: ^14.7.0
  
  # Shorebird (OTA Updates)
  shorebird_code_push: ^0.3.0
  
  # Local Storage
  hive: ^2.2.3
  shared_preferences: ^2.2.2
  
  # UI
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^3.0.0
  
  # Maps (⚠️ Consider flutter_map for cost savings)
  google_maps_flutter: ^2.5.0
  # flutter_map: ^6.1.0  # Free alternative with OpenStreetMap
  geolocator: ^11.0.0
  
  # Image
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  
  # Payment
  webview_flutter: ^4.4.4
  
  # Utils
  intl: ^0.19.0
  url_launcher: ^6.2.3
```

### Shorebird CI/CD Example (GitHub Actions)

```yaml
name: Shorebird Patch Release

on:
  push:
    tags:
      - 'patch-*'

jobs:
  patch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - uses: shorebirdtech/setup-shorebird@v1
      
      - name: Push Patch
        run: |
          shorebird patch android --force
        env:
          SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
```

### Patch Rollback Strategy

```dart
// Rollback logic in Flutter app
import 'package:shorebird_code_push/shorebird_code_push.dart';

final updater = ShorebirdCodePush();

// Check for updates
final updateAvailable = await updater.isNewPatchAvailableForDownload();

if (updateAvailable) {
  // Download in background
  await updater.downloadUpdateIfAvailable();
  
  // Apply on next restart
  // Or apply immediately with Phoenix restart package
}

// If patch causes crashes (detected by analytics)
await updater.reset(); // Reverts to base release
```

---

## Docker Compose (Complete Setup)

```yaml
version: '3.8'

services:
  # API Gateway
  api-gateway:
    build: ./backend/ApiGateway
    ports:
      - "5000:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    depends_on:
      - rabbitmq
      
  # Microservices
  auth-service:
    build: ./backend/AuthService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net
      - MongoDBSettings__DatabaseName=emlaktan
      - RabbitMQ__Host=rabbitmq
    depends_on:
      - rabbitmq
      
  listings-service:
    build: ./backend/ListingsService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net
      - MongoDBSettings__DatabaseName=emlaktan
      - RabbitMQ__Host=rabbitmq
      - Elasticsearch__Uri=http://elasticsearch:9200
    depends_on:
      - rabbitmq
      - elasticsearch
      
  payment-service:
    build: ./backend/PaymentService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net
      - MongoDBSettings__DatabaseName=emlaktan
      - RabbitMQ__Host=rabbitmq
      - Iyzico__ApiKey=${IYZICO_API_KEY}
      - Iyzico__SecretKey=${IYZICO_SECRET_KEY}
    depends_on:
      - rabbitmq
      
  messaging-service:
    build: ./backend/MessagingService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net
      - MongoDBSettings__DatabaseName=emlaktan
      - Redis__ConnectionString=redis:6379
    depends_on:
      - redis
      
  notification-service:
    build: ./backend/NotificationService
    environment:
      - RabbitMQ__Host=rabbitmq
      - Firebase__ServiceAccountKey=/secrets/firebase-key.json
      - Twilio__AccountSid=${TWILIO_ACCOUNT_SID}
      - SendGrid__ApiKey=${SENDGRID_API_KEY}
    depends_on:
      - rabbitmq
      
  # Infrastructure Services
  rabbitmq:
    image: rabbitmq:3.12-management
    ports:
      - "5672:5672"   # AMQP
      - "15672:15672" # Management UI
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    environment:
      - RABBITMQ_DEFAULT_USER=emlaktan
      - RABBITMQ_DEFAULT_PASS=emlaktan123
      
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

volumes:
  rabbitmq-data:
  elasticsearch-data:
  redis-data:
```

---

## Revised Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Planning** | 1 week | Finalized architecture, approved plan |
| **Phase 2: Infrastructure** | 1 week | RabbitMQ, Elasticsearch, Docker setup |
| **Phase 3: Backend Core** | 4 weeks | Auth, Listings, Payment services |
| **Phase 4: Backend Extended** | 3 weeks | Messaging, Notifications, Analytics |
| **Phase 5: Flutter Core** | 5 weeks | Auth, Home, Listings, Search |
| **Phase 6: Flutter Extended** | 3 weeks | Messages, Premium, Maps, Alarms |
| **Phase 7: Shorebird Setup** | 1 week | OTA pipeline, rollback testing |
| **Phase 8: Admin Panel** | 2 weeks | Blazor/React admin |
| **Phase 9: Testing** | 2 weeks | E2E, load testing |
| **Phase 10: Deployment** | 1 week | Production deployment |
| **Total** | **~23 weeks** | Full production launch |

**Timeline Increase**: +3 weeks (for RabbitMQ, Elasticsearch, Shorebird integration)  
**ROI**: Production-grade architecture with true OTA capability

---

## Recommended Development Order

### Week 1-2: Foundation
1. Setup MongoDB Atlas connection from .NET
2. RabbitMQ + Elasticsearch Docker Compose
3. Event schema definitions
4. Shorebird account + CLI setup

### Week 3-6: AuthService + ListingsService
1. AuthService with event publishing
2. ListingsService with MongoDB + Elasticsearch dual-write
3. RabbitMQ event flow testing

### Week 7-9: PaymentService (Critical!)
1. iyzico sandbox integration
2. MongoDB transactions testing
3. Event-driven premium activation

### Week 10-14: Flutter App Core
1. Riverpod state management
2. API integration with .NET backend
3. Shorebird initialization

### Week 15-23: Complete remaining features

---

## Addressing Senior Developer Concerns

### ✅ Concern 1: OTA Code Updates
**Solution**: Shorebird integration (week 17)

### ✅ Concern 2: Distributed Monolith
**Solution**: RabbitMQ event bus, clear service boundaries

### ✅ Concern 3: Search Performance
**Solution**: Elasticsearch for all listing queries

### ✅ Concern 4: MongoDB Transactions
**Acknowledged**: PaymentService uses MongoDB sessions for ACID compliance

### ✅ Concern 5: Google Maps Cost
**Option**: Can switch to `flutter_map` + OpenStreetMap (free alternative)

---

## Next Steps - Developer Choice

**Option A: Start with Backend (Recommended)**
```
1. Create AuthService (.NET project)
2. MongoDB connection
3. JWT authentication
4. RabbitMQ publisher setup
5. Docker Compose testing
```

**Option B: Start with Flutter + Shorebird**
```
1. Initialize Flutter project
2. Shorebird account + CLI
3. Create first patch
4. Test OTA update flow
5. Setup Riverpod state management
```

**Which path would you like to take?**

---

## Production Deployment Checklist

- [ ] MongoDB Atlas IP whitelist configured
- [ ] RabbitMQ admin credentials secured
- [ ] Elasticsearch authentication enabled (production)
- [ ] Redis password protection
- [ ] Shorebird release keys secured in CI/CD
- [ ] Firebase service account key (secure storage)
- [ ] iyzico production keys (encrypted)
- [ ] SSL certificates for API Gateway
- [ ] Docker images published to private registry
- [ ] Kubernetes/Docker Swarm cluster ready
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Logging (ELK stack or Seq)

---

**This revised plan is now production-ready and addresses all critical architectural gaps.**

Mehmet Bey, hangi servisden başlamak istersiniz?
- **A) AuthService** (.NET backend)
- **B) Flutter + Shorebird** (mobil uygulama OTA kurulumu)
- **C) Infrastructure** (RabbitMQ + Elasticsearch Docker setup)
