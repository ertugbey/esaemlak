# Emlaktan Migration: Flutter + .NET Microservices Implementation Plan

## Overview

This plan outlines the complete migration of the Emlaktan real estate platform from:
- **Current**: React Native (Expo) + Express.js + MongoDB
- **Target**: Flutter + .NET Core Microservices + MongoDB Atlas (existing cluster)

**Key Requirement**: Enable server-side updates without Google Play Store republishing using Firebase Remote Config and feature flags.

---

## User Review Required

> [!IMPORTANT]
> **Major Technology Stack Change**
> This migration represents a complete rewrite of the application. Before proceeding, please confirm:
> 1. Budget and timeline expectations (~21 weeks estimated)
> 2. Cloud provider preference (Azure, AWS, or current Hetzner setup)
> 3. Admin panel technology (Blazor, React, or Angular)
> 4. State management preference for Flutter (Riverpod, Bloc, or GetX)
> 
> **✅ Confirmed**: Using existing MongoDB Atlas cluster (no data migration needed!)

> [!NOTE]
> **No Data Migration Needed**
> We'll use your existing MongoDB Atlas cluster, so all current data remains intact. The .NET microservices will connect to the same database using MongoDB.Driver.

> [!CAUTION]
> **Remote Config Limitations**
> While Firebase Remote Config enables many updates without app republishing, the following still require app updates:
> - Native code changes
> - New Android/iOS permissions
> - Major architectural changes
> - New third-party SDK integrations

---

## Architecture Overview

```mermaid
graph TB
    subgraph "Mobile App - Flutter"
        UI[UI Layer]
        STATE[State Management<br/>Riverpod/Bloc]
        REMOTE[Firebase Remote Config]
        HTTP[HTTP Client<br/>Dio]
        SIGNALR[SignalR Client]
        CACHE[Local Cache<br/>Hive/SQLite]
    end
    
    subgraph "API Gateway - .NET"
        GATEWAY[Ocelot/YARP Gateway]
        AUTH_MW[Auth Middleware]
        RATE[Rate Limiter]
    end
    
    subgraph "Microservices - .NET Core"
        AUTH_MS[Auth Service]
        LISTING_MS[Listings Service]
        MSG_MS[Messaging Service<br/>SignalR]
        PAY_MS[Payment Service]
        NOTIF_MS[Notification Service]
        ANALYTICS_MS[Analytics Service]
        CONFIG_MS[Remote Config API]
    end
    
    subgraph "Database"
        MONGODB[(MongoDB Atlas<br/>emlaktan-cluster)]
    end
    
    subgraph "External Services"
        FIREBASE[Firebase<br/>Push & Remote Config]
        IYZICO[iyzico Payment]
        TWILIO[Twilio SMS]
        SENDGRID[SendGrid Email]
        MAPS[Google Maps API]
    end
    
    UI --> STATE
    STATE --> REMOTE
    STATE --> HTTP
    STATE --> SIGNALR
    STATE --> CACHE
    
    HTTP --> GATEWAY
    SIGNALR --> MSG_MS
    
    GATEWAY --> AUTH_MW
    AUTH_MW --> RATE
    RATE --> AUTH_MS
    RATE --> LISTING_MS
    RATE --> MSG_MS
    RATE --> PAY_MS
    RATE --> NOTIF_MS
    RATE --> ANALYTICS_MS
    RATE --> CONFIG_MS
    
    AUTH_MS --> MONGODB
    LISTING_MS --> MONGODB
    MSG_MS --> MONGODB
    PAY_MS --> MONGODB
    NOTIF_MS --> MONGODB
    ANALYTICS_MS --> MONGODB
    CONFIG_MS --> MONGODB
    
    NOTIF_MS --> FIREBASE
    PAY_MS --> IYZICO
    NOTIF_MS --> TWILIO
    NOTIF_MS --> SENDGRID
    LISTING_MS --> MAPS
    
    REMOTE --> CONFIG_MS
```

---

## Proposed Changes

### Backend Microservices (.NET Core 8.0)

#### 1. Auth & User Microservice
**Location**: `/backend/AuthService/`

**Responsibilities**:
- User registration & login
- JWT token generation & validation
- 2FA with QR codes (Google Authenticator)
- Password reset via email/SMS
- Role-based authorization (Admin, Emlakçı, Kullanıcı)
- Profile management

**Tech Stack**:
- ASP.NET Core 8.0 Web API
- MongoDB.Driver (official .NET driver)
- BCrypt.Net (password hashing)
- MailKit (email)
- Twilio SDK (SMS)

**Key Endpoints**:
```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh-token
POST /api/auth/enable-2fa
POST /api/auth/verify-2fa
POST /api/auth/forgot-password
POST /api/auth/reset-password
GET  /api/users/profile
PUT  /api/users/profile
```

---

#### 2. Listings Microservice
**Location**: `/backend/ListingsService/`

**Responsibilities**:
- Listing CRUD operations
- Image upload & compression
- Geospatial queries (nearby listings)
- Advanced search & filtering
- Featured listings management
- Listing analytics

**Tech Stack**:
- ASP.NET Core 8.0 Web API
- MongoDB.Driver (with GeoJSON support)
- ImageSharp (image processing)
- Azure Blob Storage / Local Storage

**Key Endpoints**:
```
GET    /api/listings
GET    /api/listings/{id}
POST   /api/listings
PUT    /api/listings/{id}
DELETE /api/listings/{id}
GET    /api/listings/nearby?lat={lat}&lng={lng}&radius={radius}
GET    /api/listings/search
POST   /api/listings/{id}/images
DELETE /api/listings/{id}/images/{imageId}
GET    /api/listings/featured
```

**MongoDB Model** (C# BSON):
```csharp
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver.GeoJsonObjectModel;

public class Listing
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }
    
    [BsonElement("emlakci")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string EmlakciId { get; set; }
    
    [BsonElement("baslik")]
    public string Baslik { get; set; }
    
    [BsonElement("aciklama")]
    public string Aciklama { get; set; }
    
    [BsonElement("fiyat")]
    public decimal Fiyat { get; set; }
    
    [BsonElement("paraBirimi")]
    public string ParaBirimi { get; set; } = "TL";
    
    [BsonElement("metrekare")]
    public double Metrekare { get; set; }
    
    [BsonElement("emlakTipi")]
    public string EmlakTipi { get; set; }
    
    [BsonElement("konutTipi")]
    public string KonutTipi { get; set; }
    
    [BsonElement("islemTipi")]
    public string IslemTipi { get; set; }
    
    [BsonElement("odaSayisi")]
    public string OdaSayisi { get; set; }
    
    [BsonElement("binaYasi")]
    public string BinaYasi { get; set; }
    
    [BsonElement("isitmaTipi")]
    public string IsitmaTipi { get; set; }
    
    [BsonElement("konum")]
    public GeoJsonPoint<GeoJson2DGeographicCoordinates> Konum { get; set; }
    
    [BsonElement("resimler")]
    public List<string> Resimler { get; set; }
    
    [BsonElement("aktif")]
    public bool Aktif { get; set; }
    
    [BsonElement("onayli")]
    public bool Onayli { get; set; }
    
    [BsonElement("goruntulenme")]
    public int Goruntulenme { get; set; }
    
    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; }
    
    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; }
}

// Repository pattern example
public class ListingRepository
{
    private readonly IMongoCollection<Listing> _listings;
    
    public ListingRepository(IMongoDatabase database)
    {
        _listings = database.GetCollection<Listing>("ilans");
    }
    
    public async Task<List<Listing>> GetNearbyAsync(double lat, double lng, double radiusInMeters)
    {
        var point = GeoJson.Point(GeoJson.Geographic(lng, lat));
        var filter = Builders<Listing>.Filter.Near(x => x.Konum, point, radiusInMeters);
        return await _listings.Find(filter).ToListAsync();
    }
}
```

---

#### 3. Messaging Microservice (SignalR)
**Location**: `/backend/MessagingService/`

**Responsibilities**:
- Real-time messaging via SignalR
- Message persistence
- Conversation threading
- Read receipts
- Typing indicators
- Online/offline status

**Tech Stack**:
- ASP.NET Core 8.0 Web API
- SignalR
- MongoDB.Driver
- Redis (for scaling SignalR)

**SignalR Hub Methods**:
```csharp
public async Task SendMessage(string conversationKey, string message)
public async Task MarkAsRead(string conversationKey)
public async Task JoinConversation(string conversationKey)
public async Task LeaveConversation(string conversationKey)
public async Task Typing(string conversationKey)
```

---

#### 4. Payment Microservice
**Location**: `/backend/PaymentService/`

**Responsibilities**:
- iyzico payment integration
- Premium subscription management
- Transaction history
- Invoice generation
- Webhook handling

**Tech Stack**:
- ASP.NET Core 8.0 Web API
- Iyzipay .NET SDK
- MongoDB.Driver

**Key Endpoints**:
```
POST /api/payment/initialize
POST /api/payment/callback
GET  /api/payment/transactions
GET  /api/premium/plans
POST /api/premium/subscribe
```

---

#### 5. Notification Microservice
**Location**: `/backend/NotificationService/`

**Responsibilities**:
- Push notifications (Firebase)
- SMS notifications (Twilio)
- Email notifications (SendGrid)
- Notification preferences
- Notification history

**Tech Stack**:
- ASP.NET Core 8.0 Web API
- FirebaseAdmin SDK
- Twilio SDK
- SendGrid SDK

---

#### 6. Analytics & Alarms Microservice
**Location**: `/backend/AnalyticsService/`

**Responsibilities**:
- Price alert management
- Market analysis
- View tracking
- User activity analytics
- Dashboard statistics

---

#### 7. Remote Config API
**Location**: `/backend/ConfigService/`

**Responsibilities**:
- Serve dynamic configuration
- Feature flags
- UI customization settings
- Content management
- A/B testing parameters

**Key Configuration Types**:
```json
{
  "features": {
    "darkMode": true,
    "premiumBadge": true,
    "chatEnabled": true,
    "mapRadius": 5000
  },
  "theme": {
    "primaryColor": "#1A3A5C",
    "accentColor": "#F5B800"
  },
  "content": {
    "welcomeMessage": "Isparta'nın en güvenilir emlak platformu",
    "featuredCategories": ["ev", "arsa", "villa"]
  }
}
```

---

#### 8. API Gateway (Ocelot/YARP)
**Location**: `/backend/ApiGateway/`

**Responsibilities**:
- Route aggregation
- Load balancing
- Authentication/Authorization
- Rate limiting
- Request/Response transformation

**Example ocelot.json**:
```json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/auth/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        { "Host": "authservice", "Port": 5001 }
      ],
      "UpstreamPathTemplate": "/api/auth/{everything}",
      "UpstreamHttpMethod": [ "GET", "POST", "PUT", "DELETE" ]
    },
    {
      "DownstreamPathTemplate": "/api/listings/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        { "Host": "listingsservice", "Port": 5002 }
      ],
      "UpstreamPathTemplate": "/api/listings/{everything}",
      "UpstreamHttpMethod": [ "GET", "POST", "PUT", "DELETE" ],
      "AuthenticationOptions": {
        "AuthenticationProviderKey": "Bearer"
      },
      "RateLimitOptions": {
        "ClientWhitelist": [],
        "EnableRateLimiting": true,
        "Period": "1m",
        "PeriodTimespan": 60,
        "Limit": 100
      }
    }
  ]
}
```

---

### Flutter Mobile Application

#### Project Structure
```
flutter_emlaktan/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   │   ├── remote_config.dart
│   │   │   ├── theme.dart
│   │   │   └── routes.dart
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── app_constants.dart
│   │   │   └── asset_constants.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── signalr_client.dart
│   │   │   └── api_interceptor.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       ├── formatters.dart
│   │       └── helpers.dart
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── providers/
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── listings/
│   │   │   ├── search/
│   │   │   ├── messages/
│   │   │   ├── profile/
│   │   │   └── premium/
│   │   ├── widgets/
│   │   └── providers/ (Riverpod)
│   └── di/
│       └── injection.dart
├── assets/
│   ├── images/
│   │   └── logos/
│   ├── icons/
│   └── animations/
└── pubspec.yaml
```

#### Key Dependencies
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
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  
  # UI
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^3.0.0
  
  # Maps
  google_maps_flutter: ^2.5.0
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

#### State Management (Riverpod)

**Auth Provider Example**:
```dart
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    _loadToken();
    return const AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final response = await ref.read(authRepositoryProvider).login(email, password);
      await _saveToken(response.token);
      state = AuthState.authenticated(user: response.user);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  Future<void> _loadToken() async {
    final token = await ref.read(localStorageProvider).getToken();
    if (token != null) {
      // Validate token and get user
      try {
        final user = await ref.read(authRepositoryProvider).getProfile();
        state = AuthState.authenticated(user: user);
      } catch (e) {
        state = const AuthState.unauthenticated();
      }
    }
  }
}
```

#### Remote Config Implementation

```dart
class RemoteConfigService {
  static final _instance = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _instance.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _instance.setDefaults({
      'theme_primary_color': '#1A3A5C',
      'theme_accent_color': '#F5B800',
      'feature_dark_mode': true,
      'feature_chat_enabled': true,
      'map_default_radius': 5000,
      'welcome_message': 'Hoş geldiniz',
    });

    await _instance.fetchAndActivate();
  }

  static String getString(String key) => _instance.getString(key);
  static bool getBool(String key) => _instance.getBool(key);
  static int getInt(String key) => _instance.getInt(key);
  static double getDouble(String key) => _instance.getDouble(key);
}

// Usage in app
final primaryColor = Color(
  int.parse(RemoteConfigService.getString('theme_primary_color')
    .replaceAll('#', '0xFF'))
);
```

---

### MongoDB Atlas Connection Setup

#### Connection String Configuration

**Your MongoDB Atlas Cluster**:
```
Connection URI: mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net/?appName=emlaktan-cluster
Database: emlaktan (or your existing database name)
```

#### .NET Microservice Configuration

**appsettings.json** (each microservice):
```json
{
  "MongoDBSettings": {
    "ConnectionString": "mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net/?appName=emlaktan-cluster",
    "DatabaseName": "emlaktan",
    "Collections": {
      "Users": "emlakcis",
      "Listings": "ilans",
      "Messages": "mesajs",
      "Payments": "payments",
      "Notifications": "notifications",
      "Favorites": "favorites",
      "Alarms": "fiyatalarms"
    }
  }
}
```

**Dependency Injection Setup** (Program.cs):
```csharp
using MongoDB.Driver;

// Configure MongoDB
builder.Services.Configure<MongoDBSettings>(
    builder.Configuration.GetSection("MongoDBSettings"));

builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var settings = sp.GetRequiredService<IOptions<MongoDBSettings>>().Value;
    return new MongoClient(settings.ConnectionString);
});

builder.Services.AddScoped<IMongoDatabase>(sp =>
{
    var settings = sp.GetRequiredService<IOptions<MongoDBSettings>>().Value;
    var client = sp.GetRequiredService<IMongoClient>();
    return client.GetDatabase(settings.DatabaseName);
});

// Register repositories
builder.Services.AddScoped<IListingRepository, ListingRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
```

**MongoDB Settings Model**:
```csharp
public class MongoDBSettings
{
    public string ConnectionString { get; set; }
    public string DatabaseName { get; set; }
    public CollectionNames Collections { get; set; }
}

public class CollectionNames
{
    public string Users { get; set; }
    public string Listings { get; set; }
    public string Messages { get; set; }
    public string Payments { get; set; }
    public string Notifications { get; set; }
    public string Favorites { get; set; }
    public string Alarms { get; set; }
}
```

#### Using Existing Schema

Since we're keeping your existing MongoDB schema, the .NET models will map directly to your current collections:
- `emlakcis` → User/Emlakci entities
- `ilans` → Listing entities  
- `mesajs` → Message entities
- etc.

No data migration needed! All existing data works as-is.

---

### Admin Panel

#### Technology Options

**Option 1: Blazor WebAssembly (Recommended)**
- Advantages: C# everywhere, shared models, type safety
- Tech: Blazor WebAssembly + MudBlazor UI

**Option 2: React + Vite**
- Advantages: Rich ecosystem, familiar to current codebase
- Tech: React + TypeScript + Ant Design

**Option 3: Angular**
- Advantages: Enterprise-ready, comprehensive
- Tech: Angular + Angular Material

#### Admin Features
- User management & moderation
- Listing approval workflow
- Analytics dashboard
- Remote config editor
- Payment transaction viewer
- System logs & monitoring

---

## Deployment Architecture

### Docker Compose (Development)

```yaml
version: '3.8'

services:
  api-gateway:
    build: ./backend/ApiGateway
    ports:
      - "5000:80"
    depends_on:
      - auth-service
      - listings-service
      - messaging-service
      
  auth-service:
    build: ./backend/AuthService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net/?appName=emlaktan-cluster
      - MongoDBSettings__DatabaseName=emlaktan
      
  listings-service:
    build: ./backend/ListingsService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net/?appName=emlaktan-cluster
      - MongoDBSettings__DatabaseName=emlaktan
      
  messaging-service:
    build: ./backend/MessagingService
    environment:
      - MongoDBSettings__ConnectionString=mongodb+srv://emlaktan_admin:xHJ8MqBLJlW71X9w@emlaktan-cluster.yznjhj.mongodb.net/?appName=emlaktan-cluster
      - MongoDBSettings__DatabaseName=emlaktan
      - Redis__ConnectionString=redis:6379
      
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

volumes:
  redis-data:
```

### Production Deployment (Hetzner/Azure)

**Infrastructure**:
- Kubernetes cluster or Docker Swarm
- Load balancer (Nginx/HAProxy)
- MongoDB Atlas (existing cluster - already configured!)
- Redis cluster for SignalR
- Azure Blob Storage / S3 / Hetzner Storage for images

---

## Remote Update Strategy

### What Can Be Updated Without App Republish

✅ **Can Update**:
- Theme colors & styles
- Feature flags (enable/disable features)
- API endpoints (via remote config)
- Content (welcome messages, categories)
- Business logic parameters (map radius, limits)
- A/B test variants

❌ **Cannot Update** (Requires App Update):
- Flutter widget structure
- Native permissions
- New packages/dependencies
- Platform-specific code

### Implementation Example

```dart
// In Flutter App
class AppFeatures {
  static bool get isDarkModeEnabled => 
    RemoteConfigService.getBool('feature_dark_mode');
    
  static bool get isChatEnabled => 
    RemoteConfigService.getBool('feature_chat_enabled');
    
  static int get mapRadius => 
    RemoteConfigService.getInt('map_default_radius');
}

// Usage
if (AppFeatures.isChatEnabled) {
  // Show chat button
}
```

---

## Migration Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Planning** | 1 week | Architecture, MongoDB models, API contracts |
| **Phase 2: Backend Core** | 3-4 weeks | Auth, Listings, Messaging services |
| **Phase 3: Backend Extended** | 2-3 weeks | Payment, Notifications, Analytics |
| **Phase 4: Flutter App Core** | 5 weeks | Auth, Home, Listings, Search |
| **Phase 5: Flutter Extended** | 3 weeks | Messages, Premium, Alarms, Maps |
| **Phase 6: Admin Panel** | 2 weeks | Basic admin functionality |
| **Phase 7: Testing** | 2 weeks | Integration, E2E tests |
| **Phase 8: Deployment** | 1 week | Production setup |
| **Total** | **~19-21 weeks** | Full production launch |

> **Note**: Using existing MongoDB Atlas cluster saves 1-2 weeks (no data migration phase needed)!

---

## Verification Plan

### Automated Tests
```bash
# Backend (.NET)
dotnet test backend/Tests/AuthService.Tests
dotnet test backend/Tests/ListingsService.Tests
dotnet test backend/Tests/Integration.Tests

# Flutter
flutter test
flutter integration_test
```

### Manual Verification
- User registration & login flow
- Listing CRUD operations
- Real-time messaging
- Payment processing
- Push notifications
- Remote config updates
- Map functionality
- Image uploads

### Performance Testing
- Load testing with k6/JMeter
- SignalR concurrent connections test
- Database query optimization
- Image compression verification

---

## Next Steps

1. **User Decision Points**:
   - Confirm technology choices (database, admin panel, state management)
   - Define priority features for MVP
   - Allocate budget & resources
   
2. **Initial Setup**:
   - Create .NET solution structure
   - Initialize Flutter project
   - Setup Firebase project
   - Configure Docker environment
   
3. **Start Development**:
   - Begin with Auth microservice
   - Setup API Gateway
   - Build Flutter authentication screens
