# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SignLearn is a cross-platform mobile application for teaching sign language. This is a **Flutter** implementation that replicates the original .NET MAUI application. The app connects to a shared ASP.NET Core REST API hosted on Railway, which interfaces with MongoDB Atlas.

**Architecture:**
```
[Flutter App] <--> [ASP.NET Core API (Railway)] <--> [MongoDB Atlas]
```

**Key Technologies:**
- Flutter 3.35.7 / Dart 3.9.2
- ASP.NET Core (.NET 8) for API
- MongoDB Atlas (3 collections: Usuarios, Progresion, Niveles)

## Running the Application

### Flutter App (Current Working Directory)

```bash
# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Run on different platforms
flutter run                    # Auto-detect device
flutter run -d windows         # Windows
flutter run -d chrome          # Web
flutter run -d android         # Android

# Development commands
flutter analyze                # Static analysis
flutter test                   # Run tests
```

### ASP.NET Core API (Parent Directory)

```bash
cd ../InclusingLenguage.API

# Build and run the API
dotnet clean
dotnet build
dotnet run

# API runs at:
# - Local: https://localhost:7246
# - Production: https://inclusing-lenguage-api-production.up.railway.app
```

## Critical Architecture Concepts

### MongoDB Collection Structure

The app uses **3 MongoDB collections** (NOT a "users" collection):

1. **Usuarios** - User authentication and basic info
   - Fields: `usuarioID`, `nombre`, `correo`, `pass`, `fechaRegistro`
   - Primary key: `usuarioID` (NOT email)

2. **Progresion** - User progress tracking
   - Fields: `usuarioID`, `nivelActual`, `nivelesCompletados[]`, `intentos[]`, `estadisticas{}`
   - Tracks completed levels and attempt history

3. **Niveles** - Level/lesson definitions
   - Fields: `nivelID`, `nombre`, `maxIntentos`, `recompensa{puntos}`
   - Static data defining available lessons

### Flutter <-> API Data Flow

**Authentication Flow:**
- User registers/logs in via `/auth/register` or `/auth/login`
- API returns `usuarioID` and token
- Flutter stores `usuarioID` in secure storage (migration support for email-based users)

**Lesson Progress Flow:**
- Flutter displays lessons from local data (`lib/data/lesson_data.dart`)
- User completes lesson -> Flutter calls:
  1. `POST /progresion/registrar-intento` (records attempt)
  2. `POST /progresion/completar-nivel` (if successful)
- API updates `Progresion` collection automatically

**Key Implementation Detail:**
- `LessonService.getUsuarioID()` handles migration: checks secure storage first, falls back to email lookup via API
- Lesson data is **local** (hardcoded), progress tracking is **remote** (API/MongoDB)

### Service Layer Architecture

**Flutter Services (Singleton Pattern):**
- `ApiService` - HTTP client wrapper (all API calls)
- `AuthService` - Authentication state management
- `LessonService` - Combines local lesson data with remote progress
- `StorageService` - Secure storage and SharedPreferences

**API Structure:**
- `Controllers/` - REST endpoints (Auth, Usuarios, Progresion, Niveles)
- `Services/MongoDBService.cs` - MongoDB connection and collections
- `Models/` - C# models matching MongoDB documents

### Important Migration Logic

The app supports **usuarioID-based** authentication but has migration code for users created with email-only:
- `LessonService.getUsuarioID()` (lines 107-155) handles fallback to email lookup
- `AuthService` stores both email and usuarioID after login
- API endpoint `GET /usuarios/by-email/{email}` exists for migration

## Configuration

### API Endpoint
Located in `lib/utils/constants.dart`:
```dart
static const String baseUrl = 'https://inclusing-lenguage-api-production.up.railway.app/api';
```

For local API testing, change to:
```dart
static const String baseUrl = 'http://localhost:5246/api';  // Windows
// or 'http://10.0.2.2:5246/api' for Android emulator
```

### MongoDB Configuration
Located in `../InclusingLenguage.API/appsettings.json`:
- Database name: `inclusign` (NOT `includesign`)
- Collections: `Usuarios`, `Progresion`, `Niveles`

## Common Development Patterns

### Adding a New API Endpoint

1. **API Side** (`../InclusingLenguage.API/`):
   - Add method to appropriate controller in `Controllers/`
   - Use `IMongoDBService` to access collections
   - Return proper HTTP status codes

2. **Flutter Side**:
   - Add method to `lib/services/api_service.dart` using `_makeRequest()`
   - Add business logic method to appropriate service (e.g., `lesson_service.dart`)
   - Update UI screens in `lib/screens/`

### Working with User Progress

Always use `LessonService` methods, not direct API calls:
```dart
// Get user progress
final progresion = await LessonService().getProgresionUsuario(usuarioID);

// Complete a lesson (handles both intento and nivel completion)
await LessonService().completeLesson(
  lessonId: 5,
  score: 8,
  totalPoints: 10,
);
```

### Models Pattern

**Two types of models:**
1. `mongodb_models.dart` - Exact MongoDB document structure (Usuarios, Progresion, Niveles)
2. `lesson.dart`, `user_profile.dart` - UI-friendly models for Flutter widgets

Services bridge between these (e.g., `LessonService.getAllLessons()` combines local lesson data with remote Progresion)

## Known Issues & Warnings

- `withOpacity` deprecation warnings in Flutter 3.35+ (non-critical)
- BuildContext warnings in async code (standard Flutter practice)
- Guest mode (`guest@signlearn.com`) does not save progress
- CORS is wide open (`AllowAll`) - restrict for production

## Testing the API

Use Swagger UI when running API locally:
```
https://localhost:7246/swagger
```

Or test with curl:
```bash
# Test user login
curl -X POST "https://inclusing-lenguage-api-production.up.railway.app/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get user progress
curl "https://inclusing-lenguage-api-production.up.railway.app/api/progresion/{usuarioID}"
```

## File Structure Key Locations

**Flutter App:**
- `lib/services/api_service.dart` - All API HTTP calls
- `lib/services/lesson_service.dart` - Lesson + progress business logic
- `lib/models/mongodb_models.dart` - MongoDB document models
- `lib/screens/lesson_screen.dart` - Main lesson UI
- `lib/data/lesson_data.dart` - Local lesson content

**API:**
- `Controllers/ProgresionController.cs` - Progress tracking endpoints
- `Controllers/AuthController.cs` - Registration/login
- `Services/MongoDBService.cs` - MongoDB connection
- `Models/Progresion.cs`, `Nivel.cs` - C# models

## State Management

Currently uses `setState()` for local state. The app uses a simple pattern:
- Services are singletons (factory pattern)
- Authentication state in `AuthService` + secure storage
- No complex state management (Provider is installed but minimally used)

When adding features, continue with setState or consider migrating to Provider if state becomes complex.
