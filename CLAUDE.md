# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inclusign** (SignLearn) is a cross-platform mobile application for teaching sign language through interactive lessons.

**Repository Structure:**
- `inclusing_language_flutter/` - Flutter mobile app (primary client)
- `api_dart/` - Dart/Shelf REST API (production backend, deployed on Railway)
- `api_node/` - Node.js/Express API (alternative implementation)
- `django-rest-framework/` - Django API (alternative implementation)
- **Python ML Scripts** - MediaPipe landmark extraction and gesture recognition testing

**Current Production Architecture:**
```
[Flutter App] <--> [Dart/Shelf API (Railway)] <--> [MongoDB Atlas]
     ^                                                    |
     |                                                    |
     +-------- Local GIF Assets (assets/gifs/) ----------+

Gesture Recognition Pipeline (Experimental):
[Flutter Camera] → [MediaPipe Server (Python)] → [Django API (TensorFlow)] → [Prediction]
                    Extract 81 landmarks           Accumulate 65 frames
                    (81×3 = 243 values)            Classify gesture
```

**Key Technologies:**
- Flutter 3.35.7 / Dart 3.9.2
- Dart Shelf framework (production API)
- MongoDB Atlas (5 collections: Usuarios, Progresion, Niveles, Abecedario, Gestos)
- **MediaPipe Python** (Holistic landmark extraction for gesture recognition)
- **TensorFlow/Keras** (Gesture classification model in Django API)
- **Flask** (MediaPipe landmark extraction server)

**Lesson Content:**
- 58 lessons total: 27 alphabet (A-Z + Ñ), 10 numbers (0-9), 21 gestures (greetings/phrases)
- Lesson definitions hardcoded in `lib/data/lesson_data.dart` (local, instant access)
- User progress tracked remotely in MongoDB (Progresion collection)
- GIF assets bundled locally in app (migrated from MongoDB for performance)

## Running the Application

### Flutter App

```bash
cd inclusing_language_flutter

# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Run on different platforms
flutter run                    # Auto-detect device
flutter run -d windows         # Windows
flutter run -d chrome          # Web
flutter run -d android         # Android

# Build for release
flutter build apk              # Android APK (debug)
flutter build apk --release    # Android APK (release)
flutter build appbundle        # Android App Bundle (for Play Store)
flutter build windows          # Windows executable

# Development commands
flutter analyze                # Static analysis
flutter test                   # Run tests
flutter clean                  # Clean build artifacts
```

### Dart API Backend (Production)

```bash
cd api_dart

# Install dependencies
dart pub get

# Run the server (development)
dart run bin/server.dart

# Analyze and format
dart analyze
dart format .

# API runs at:
# - Local: http://localhost:5246
# - Production: https://inclusing-lenguage-api-production.up.railway.app
```

**Environment Variables:**
Create `.env` file in `api_dart/`:
```
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
DATABASE_NAME=inclusign
PORT=5246
```

### Node.js API (Alternative)

```bash
cd api_node

# Install dependencies
npm install

# Run the server
npm start

# API runs at:
# - Local: http://localhost:5246
```

### MediaPipe Server (Gesture Recognition)

```bash
# Install Python dependencies
pip install -r requirements_mediapipe.txt

# Test MediaPipe with webcam
python mediapipe_landmark_extractor.py

# Run the landmark extraction server
python mediapipe_server.py

# Test the complete pipeline (MediaPipe + Django API)
python test_complete_pipeline.py

# Quick test (single frame)
python test_complete_pipeline.py quick

# Server runs at:
# - Local: http://localhost:5000
# - Django API: https://django-rest-framework-uc05.onrender.com
```

**MediaPipe Dependencies:**
- `opencv-python==4.8.1.78` - Image processing
- `mediapipe==0.10.8` - Holistic landmark extraction
- `numpy==1.24.3` - Array operations
- `flask==3.0.0` - HTTP server
- `flask-cors==4.0.0` - CORS support for Flutter

## Critical Architecture Concepts

### MongoDB Collection Structure

The database uses **5 MongoDB collections**:

1. **Usuarios** - User authentication
   - Fields: `usuarioID`, `nombre`, `correo`, `pass`, `fechaRegistro`
   - Primary key: `usuarioID` (string, NOT email)

2. **Progresion** - User progress tracking
   - Fields: `usuarioID`, `nivelActual`, `nivelesCompletados[]`, `intentos[]`, `estadisticas{tiempoJugadoMin, totalIntentos, totalExitos}`
   - Links to: `Usuarios.usuarioID`

3. **Niveles** - Lesson definitions
   - Fields: `nivelID` (int), `nombre`, `maxIntentos`, `recompensa{puntos}`
   - Static lesson metadata

4. **Abecedario** - Sign language alphabet GIFs (A-Z, Ñ = 27 entries)
   - Fields: `letra`, `nombre`, `contenido` (base64 GIF)
   - **Important:** Content now loaded from local assets (`assets/gifs/abecedario/`)

5. **Gestos** - Sign language gesture GIFs (greetings, phrases = 21 entries)
   - Fields: `nombre`, `contenido` (base64 GIF)
   - **Important:** Content now loaded from local assets (`assets/gifs/gestos/`)

### GIF Loading Migration (Critical Change)

**Previous approach:** GIFs loaded from MongoDB (caused timeouts, slow loading)
**Current approach:** GIFs stored as local Flutter assets

**Implementation:**
- `lib/data/lesson_data.dart` methods:
  - `loadAbecedarioImageByLetter(String letter)` → loads from `assets/gifs/abecedario/{letra}.gif`
  - `loadSingleGestoVideo(String nombre)` → loads from `assets/gifs/gestos/{nombre}.gif`
- Uses `rootBundle.load()` for instant access
- MongoDB collections `Abecedario` and `Gestos` still exist but are not queried for content
- See `INSTRUCCIONES_GIFS_LOCALES.md` for migration details

**Required asset structure:**
```
inclusing_language_flutter/assets/gifs/
├── abecedario/     # 27 files: A.gif, B.gif, ..., Z.gif, Ñ.gif
├── gestos/         # 21 files: HOLA.gif, BUENOS_DIAS.gif, etc.
└── numeros/        # 10 files: 0.gif, 1.gif, ..., 9.gif (if implementing numbers)
```

**Note:** Numbers category exists in lesson data but GIF assets may need to be added separately.

### API Endpoint Structure

**Dart API Routes** (`api_dart/lib/routes/`):

**Auth:**
- `POST /api/auth/register` - Create new user
- `POST /api/auth/login` - Authenticate user
- Returns: `{usuarioID, token}` (token is Base64 encoded)

**Usuarios:**
- `GET /api/usuarios/:usuarioID` - Get user by ID
- `GET /api/usuarios/by-email/:email` - Get user by email (migration support)

**Progresion:**
- `GET /api/progresion/:usuarioID` - Get user progress
- `PUT /api/progresion/:usuarioID` - Update progress
- `POST /api/progresion/completar-nivel` - Mark level complete
  - Body: `{usuarioID, nivel, resultado: "exito"|"fallo", experienciaGanada}`
  - Each lesson awards 25 XP total (5 + 10 + 10 for three exercises)
- `POST /api/progresion/registrar-intento` - Record attempt
  - Body: `{usuarioID, nivel, resultado: "exito"|"fallo"}`
  - Records all attempts including failures for estadisticas tracking

**Niveles:**
- `GET /api/niveles` - Get all levels
- `GET /api/niveles/:nivelID` - Get specific level

**Abecedario & Gestos:**
- `GET /api/abecedario` - Get all alphabet entries (metadata only, GIFs not returned)
- `GET /api/gestos` - Get all gesture entries (metadata only, GIFs not returned)

### Flutter Service Architecture

**Singleton Services** (Factory pattern):

1. **ApiService** (`lib/services/api_service.dart`)
   - HTTP client wrapper using `package:http`
   - Method: `_makeRequest(method, endpoint, body?, headers?)`
   - Timeout: 120 seconds (defined in `AppConstants.requestTimeout`)
   - All API methods return parsed JSON or throw exceptions

2. **AuthService** (`lib/services/auth_service.dart`)
   - Manages authentication state
   - Stores `usuarioID` and `email` in `flutter_secure_storage`
   - Methods: `register()`, `login()`, `logout()`, `isLoggedIn()`

3. **LessonService** (`lib/services/lesson_service.dart`)
   - **Critical service** that bridges local lesson data with remote progress
   - Methods:
     - `getAllNiveles()` - Fetch from API
     - `getProgresionUsuario(usuarioID)` - Fetch from API
     - `completarNivel()` - Update progress
     - `registrarIntento()` - Record attempt
   - Handles `usuarioID` migration (falls back to email lookup)

4. **StorageService** (`lib/services/storage_service.dart`)
   - Wrapper for `flutter_secure_storage` and `shared_preferences`
   - Must call `init()` before use (called in `main.dart`)

### Data Flow: Completing a Lesson

1. User completes lesson in `lesson_screen.dart`
2. UI calls `LessonService().registrarIntento(usuarioID, nivel, exito)`
3. If successful, calls `LessonService().completarNivel(usuarioID, nivel, exito, xp)`
4. `LessonService` → `ApiService._makeRequest()` → Dart API
5. Dart API → `progresion_routes.dart` handler → `DatabaseService` (MongoDB)
6. MongoDB updates `Progresion.nivelesCompletados[]` and `Progresion.intentos[]`

### Data Flow: Gesture Recognition (Experimental)

**Note:** This feature is now fully integrated and functional. The app can recognize 21 sign language gestures in real-time using MediaPipe + TensorFlow.

1. **Capture Frame** - Flutter Camera captures YUV420 frame
2. **Convert & Encode** - Convert to JPEG, encode as base64
3. **Extract Landmarks** - Send to MediaPipe Server (`POST /extract`)
   - Server decodes image
   - MediaPipe Holistic processes frame
   - Extracts 81 landmarks: 33 pose + 6 face + 21 left hand + 21 right hand
   - Returns flat array of 243 values (81 × 3 coordinates)
4. **Accumulate Sequence** - Send landmarks to Django API (`POST /api/predict/`)
   - Django buffers frames until 65 frames collected
   - Returns `{"estado": "esperando N frames"}` while buffering
5. **Classify Gesture** - Once 65 frames ready:
   - TensorFlow model predicts gesture from sequence
   - Returns `{"gesto": "HOLA", "confianza": 0.95, "top_3": [...]}`
6. **Update UI** - Flutter updates recognition overlay and history

**Key Files:**
- `mediapipe_landmark_extractor.py` - Core MediaPipe wrapper class
- `mediapipe_server.py` - Flask server with `/extract` endpoint
- `test_complete_pipeline.py` - End-to-end testing script
- `lib/screens/gesture_camera_screen.dart` - Flutter camera UI
- `lib/services/gesture_recognition_service.dart` - API communication
- `label_encoder.pkl` - Gesture label encoder (21 gesture classes)

**Landmark Structure:**
```python
# 81 landmarks × 3 coordinates (x, y, z) = 243 values
landmarks = [
    # Pose (33 points): nose, eyes, shoulders, elbows, wrists, hips, knees, ankles, etc.
    # Face (6 specific points): indices 1, 33, 263, 61, 291, 199
    # Left Hand (21 points): wrist, thumb (4), index (4), middle (4), ring (4), pinky (4)
    # Right Hand (21 points): same structure as left hand
]
```

## Configuration

### API Endpoint Configuration

**Flutter app** (`inclusing_language_flutter/lib/utils/constants.dart`):
```dart
static const String baseUrl = 'https://inclusing-lenguage-api-production.up.railway.app/api';
```

For local development, change to:
```dart
static const String baseUrl = 'http://localhost:5246/api';         // Windows/Linux
// OR
static const String baseUrl = 'http://10.0.2.2:5246/api';         // Android emulator
```

### Theme Configuration

**Dark theme with custom colors** (`lib/utils/colors.dart`):
- Background: `#00131F`
- Card Background: `#002132`
- Primary: `#13B7FF`
- Secondary: `#86CBFF`
- Accent: `#00ABE8`

All screens use these colors via `AppColors` class.

## Common Development Patterns

### Adding a New Lesson Type

1. **Define lesson data** in `lib/data/lesson_data.dart`:
   - Add to static data arrays
   - Create GIF loading method if needed

2. **Add assets** to `assets/gifs/`:
   - Create subdirectory for new type
   - Add to `pubspec.yaml` under `flutter.assets`

3. **Update UI** in `lib/screens/lesson_screen.dart`:
   - Modify `_loadLessonContent()` to handle new type
   - Update `MediaDisplay` widget to render new format

### Adding a New API Endpoint

**Backend** (`api_dart/`):
1. Create/modify route file in `lib/routes/`
2. Add route handler method
3. Use `DatabaseService().db.collection('CollectionName')` to access MongoDB
4. Return `Response.ok()` or `Response(statusCode)` with JSON body
5. Mount route in `bin/server.dart` using `app.mount('/api/path', RouteClass().router)`

**Frontend** (`inclusing_language_flutter/`):
1. Add method to `lib/services/api_service.dart`:
   ```dart
   Future<Map<String, dynamic>?> getNewData() async {
     final response = await _makeRequest('GET', '/new-endpoint');
     if (response.statusCode == 200) {
       return jsonDecode(response.body);
     }
     return null;
   }
   ```
2. Add business logic to appropriate service
3. Update UI in screens

### Working with User Authentication

**Always use AuthService methods:**
```dart
// Check if logged in
final isLoggedIn = await AuthService().isLoggedIn();

// Get stored user ID
final usuarioID = await AuthService().getStoredUsuarioID();

// Login
final result = await AuthService().login(email, password);
if (result.isSuccess) {
  // Navigate to home
}
```

**Guest mode:**
- Special email: `guest@inclusign.com` (or `guest@signlearn.com` - check AuthService for actual value)
- No password required
- Progress not saved to server
- Useful for testing and demos

## File Structure Reference

### Flutter App (`inclusing_language_flutter/`)

**Key files:**
- `lib/main.dart` - App entry point, theme setup
- `lib/services/api_service.dart` - All HTTP requests
- `lib/services/lesson_service.dart` - **Core business logic** for lessons
- `lib/services/auth_service.dart` - Authentication flow
- `lib/data/lesson_data.dart` - **Local lesson content** (alphabet, gestures)
- `lib/models/mongodb_models.dart` - MongoDB document models
- `lib/models/lesson.dart`, `lib/models/user_profile.dart` - UI models
- `lib/screens/lesson_screen.dart` - Main lesson UI
- `lib/screens/home_screen.dart` - Dashboard with progress
- `lib/widgets/media_display.dart` - Platform-specific GIF rendering
- `assets/gifs/` - **Local GIF assets** (required for app to function)

### Dart API (`api_dart/`)

**Key files:**
- `bin/server.dart` - Entry point, route mounting, CORS
- `lib/services/database_service.dart` - MongoDB connection singleton
- `lib/services/auth_service.dart` - Password hashing (SHA-256), token generation
- `lib/routes/auth_routes.dart` - `/auth/register`, `/auth/login`
- `lib/routes/progresion_routes.dart` - **Core progress tracking endpoints**
- `lib/routes/usuarios_routes.dart` - User CRUD
- `lib/routes/niveles_routes.dart` - Level metadata
- `lib/routes/abecedario_routes.dart` - Alphabet metadata (GIFs no longer served)
- `lib/routes/gestos_routes.dart` - Gesture metadata (GIFs no longer served)
- `lib/models/usuario.dart`, `lib/models/progresion.dart`, `lib/models/nivel.dart` - Data models

## Known Issues & Considerations

**Flutter Warnings:**
- `withOpacity` deprecation in Flutter 3.35+ (non-critical, will be fixed in future Flutter releases)
- BuildContext usage in async functions (standard pattern, false positives)

**API Security:**
- CORS is set to `*` (allow all origins) - **should be restricted in production**
- Passwords hashed with SHA-256 (consider bcrypt/argon2 for production)
- No JWT validation (tokens are simple Base64, not cryptographically secure)

**Deployment:**
- **API (Dart):** Hosted on Railway with auto-deploy from git push
  - Production URL: https://inclusing-lenguage-api-production.up.railway.app
  - Railway detects Dockerfile automatically
  - Environment variables configured in Railway dashboard (.env not committed)
- **API (Node):** Can be deployed on Vercel or Railway (see `INSTRUCCIONES_APK_Y_DESPLIEGUE.md`)
- **MongoDB Atlas:** Free tier (M0) connection string in .env
  - Database name: `inclusign`
  - Network Access should allow Railway/Vercel IPs or 0.0.0.0/0
- **Flutter APK:** Build with `flutter build apk --release`
  - Output: `build/app/outputs/flutter-apk/app-release.apk`
  - Size: ~120-130 MB (includes bundled GIF assets)
  - GitHub workflow: `.github/workflows/build-apk.yml` (automated builds)

**Platform-Specific:**
- Android emulator uses `10.0.2.2` to access host `localhost`
- iOS simulator can use `localhost` directly
- Web build has CORS restrictions when accessing local API
- Windows: Use `localhost:5246` for local API development

## Testing

### Flutter App

```bash
cd inclusing_language_flutter

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

### Dart API

```bash
cd api_dart

# Check for issues
dart analyze

# Format code
dart format .

# Test API endpoints manually
curl http://localhost:5246/
curl http://localhost:5246/api/niveles
```

### Docker Deployment (API)

```bash
cd api_dart

# Build Docker image
docker build -t inclusing-api .

# Run container locally
docker run -p 5246:5246 --env-file .env inclusing-api

# Railway automatically builds from Dockerfile on git push
```

**Note:** Railway automatically detects and builds from the Dockerfile in `api_dart/`. Environment variables must be configured in the Railway dashboard (not in .env).

## State Management

**Current approach:** Simple `setState()` with singleton services
- No complex state management library (Provider installed but unused)
- Authentication state persisted in `flutter_secure_storage`
- Lesson data is stateless (hardcoded in `lesson_data.dart`)
- User progress fetched on-demand from API

**When to refactor:**
If you need to:
- Share state across many widgets without prop drilling
- Implement complex state dependencies
- Add real-time updates (WebSocket, polling)

Consider: Provider, Riverpod, or Bloc pattern.

## Important Migration Notes

**usuarioID vs Email:**
- Older code may reference email-based authentication
- Current system uses `usuarioID` as primary identifier
- `LessonService.getUsuarioID()` has fallback logic to handle migration
- API endpoint `GET /usuarios/by-email/{email}` exists for compatibility

**GIF Content Delivery:**
- Old approach: MongoDB stored base64 GIFs, API served them, Flutter downloaded
- New approach: GIFs stored as Flutter assets, instant loading
- MongoDB collections still exist but content is not queried
- If adding new gestures/letters, add GIF files to `assets/gifs/` directories

## Troubleshooting

### GIF Assets Not Loading

**Symptom:** Lessons show emoji placeholders instead of GIFs

**Solution:**
1. Verify GIF files exist:
   ```bash
   # Windows
   dir /b assets\gifs\abecedario\*.gif | find /c ".gif"  # Should show 27
   dir /b assets\gifs\gestos\*.gif | find /c ".gif"      # Should show 21

   # Linux/Mac
   ls assets/gifs/abecedario/*.gif | wc -l  # Should show 27
   ls assets/gifs/gestos/*.gif | wc -l      # Should show 21
   ```

2. Check file naming (case-sensitive):
   - Abecedario: `A.gif`, `B.gif`, ..., `Ñ.gif` (uppercase)
   - Gestos: `HOLA.gif`, `BUENOS_DIAS.gif` (uppercase with underscores)

3. Rebuild app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. If files are missing, export from MongoDB using script in `INSTRUCCIONES_GIFS_LOCALES.md`

### API Connection Timeouts

**Symptom:** HTTP requests take 1-3 minutes or timeout

**Causes:**
- MongoDB Atlas free tier (M0) cold starts
- Network latency to MongoDB cluster
- CORS issues with local development

**Solutions:**
- Timeout is set to 120 seconds in `constants.dart` - this is intentional
- For local testing, ensure API is running (`dart run bin/server.dart` in `api_dart/`)
- For Android emulator, use `http://10.0.2.2:5246/api` instead of `localhost`
- Check Railway logs if production API is down

### Authentication Failures

**Symptom:** Login fails with 404 or 401 errors

**Debugging:**
1. Verify user exists in MongoDB `Usuarios` collection
2. Check if `usuarioID` is being used correctly (not email)
3. Verify `AuthService` has stored credentials:
   ```dart
   final usuarioID = await AuthService().getStoredUsuarioID();
   print('Stored usuarioID: $usuarioID');
   ```
4. Check API logs for authentication errors
5. Ensure password is not empty and matches MongoDB hash (SHA-256)

### Progress Not Saving

**Symptom:** User progress doesn't persist across sessions

**Causes:**
- Guest mode being used
- API endpoint failures
- MongoDB connection issues
- `usuarioID` not found in Progresion collection

**Solutions:**
1. Verify not using guest account (`guest@inclusign.com`)
2. Check API response in `LessonService.completarNivel()`:
   ```dart
   // Add debug logging
   print('API Response: ${response.statusCode} ${response.body}');
   ```
3. Verify `Progresion` document exists for user in MongoDB
4. Check `estadisticas` fields are updating correctly

### MediaPipe Server Issues

**Symptom:** MediaPipe server not starting or crashes

**Causes:**
- Missing Python dependencies
- Camera already in use
- Port 5000 already occupied
- Incompatible library versions

**Solutions:**
1. Install dependencies: `pip install -r requirements_mediapipe.txt`
2. Close other apps using camera (Zoom, Teams, etc.)
3. Check port availability: `netstat -ano | findstr :5000` (Windows)
4. Verify MediaPipe version: `pip show mediapipe` (should be 0.10.8)
5. Test camera access: `python mediapipe_landmark_extractor.py`

**Debugging checklist:**
```bash
# 1. Check Python version (3.8-3.11 recommended)
python --version

# 2. Verify dependencies
pip list | findstr "mediapipe opencv flask"

# 3. Test server health
curl http://localhost:5000/health

# 4. Check for errors in server logs
python mediapipe_server.py
```

### Gesture Recognition Not Working

**Symptom:** No landmarks detected or predictions always fail

**Causes:**
- Poor lighting conditions
- Body not fully visible in frame
- Django API cold start (30+ seconds on Render)
- Insufficient frames buffered (need 65)

**Solutions:**
1. Ensure good lighting and full body visibility
2. Wait for Django API warm-up on first request
3. Check MediaPipe detections in test script:
   ```python
   python test_complete_pipeline.py
   # Watch console for "Pose ✓", "Mano Izq ✓", "Mano Der ✓"
   ```
4. Verify landmark count: Should output "243 valores" in logs
5. Check Django API directly:
   ```bash
   curl -X POST https://django-rest-framework-uc05.onrender.com/api/predict/ \
     -H "Content-Type: application/json" \
     -d '{"landmarks": [... 243 values ...]}'
   ```

**Note:** Django API on Render free tier has cold starts. First request may take 30+ seconds.

## Quick Reference

### Essential File Locations

| Purpose | Flutter Path | API Path | Python/ML Path |
|---------|-------------|----------|----------------|
| API calls | `lib/services/api_service.dart` | - | - |
| Lesson logic | `lib/services/lesson_service.dart` | - | - |
| Lesson content | `lib/data/lesson_data.dart` | - | - |
| Auth logic | `lib/services/auth_service.dart` | `lib/services/auth_service.dart` | - |
| Progress tracking | - | `lib/routes/progresion_routes.dart` | - |
| MongoDB connection | - | `lib/services/database_service.dart` | - |
| API URL config | `lib/utils/constants.dart` | - | - |
| Theme colors | `lib/utils/colors.dart` | - | - |
| Main lesson UI | `lib/screens/lesson_screen.dart` | - | - |
| Gesture recognition UI | `lib/screens/gesture_camera_screen.dart` | - | - |
| Gesture service | `lib/services/gesture_recognition_service.dart` | - | - |
| MongoDB models | `lib/models/mongodb_models.dart` | `lib/models/*.dart` | - |
| MediaPipe extraction | - | - | `mediapipe_landmark_extractor.py` |
| MediaPipe server | - | - | `mediapipe_server.py` |
| Pipeline testing | - | - | `test_complete_pipeline.py` |
| ML label encoder | - | - | `label_encoder.pkl` |

### Key Constants

- **API Port:** 5246 (Dart API)
- **MediaPipe Port:** 5000 (Flask server)
- **Django API:** https://django-rest-framework-uc05.onrender.com
- **Request Timeout:** 120 seconds (2 minutes)
- **Database Name:** `inclusign`
- **Total Lessons:** 58 (27 alphabet + 10 numbers + 21 gestures)
- **XP per Lesson:** 25 (5 + 10 + 10)
- **GIF Assets:** 48 required (27 abecedario + 21 gestos)
- **ML Model Requirements:**
  - Landmarks per frame: 81 (243 values flattened)
  - Sequence length: 65 frames
  - Gesture classes: 21

### MongoDB Collections at a Glance

```json
Usuarios: {usuarioID*, nombre, correo, pass, fechaRegistro}
Progresion: {usuarioID*, nivelActual, nivelesCompletados[], estadisticas{}}
Niveles: {nivelID*, nombre, maxIntentos, recompensa{}}
Abecedario: {nombre*, contenido} // GIFs not served via API
Gestos: {nombre*, contenido}     // GIFs not served via API
```
*Primary key

### Common Commands

```bash
# Flutter development
flutter pub get && flutter run -d windows
flutter clean && flutter pub get  # Fix asset issues
flutter analyze                    # Check for errors

# API development
cd api_dart && dart run bin/server.dart
dart analyze && dart format .      # Check and format code

# MediaPipe/ML development
pip install -r requirements_mediapipe.txt  # Install dependencies
python mediapipe_server.py                 # Start MediaPipe server
python test_complete_pipeline.py           # Test full pipeline
python test_complete_pipeline.py quick     # Quick single-frame test

# Verify GIF assets (Windows)
dir /b assets\gifs\abecedario\*.gif | find /c ".gif"
dir /b assets\gifs\gestos\*.gif | find /c ".gif"

# Test API endpoints
curl http://localhost:5246/api/niveles
curl -X POST http://localhost:5246/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"test@example.com\",\"password\":\"pass123\"}"

# Test MediaPipe server
curl http://localhost:5000/health
curl -X POST http://localhost:5000/extract -H "Content-Type: application/json" -d "{\"image\":\"base64_encoded_image\"}"
```

## Additional Documentation

For more detailed information on specific features, refer to these documentation files:

### Gesture Recognition System (Real-time)
- **`GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md`** - ⭐ COMPLETE USER GUIDE
  - Step-by-step usage instructions
  - 21 recognizable gestures
  - Troubleshooting guide
  - Technical specifications
- **`RESUMEN_INTEGRACION_COMPLETA.md`** - Integration summary
  - What was changed and why
  - File-by-file modifications
  - Performance statistics
- **`README_MEDIAPIPE.md`** - MediaPipe technical details
  - System architecture
  - Landmark structure (81 points)
  - Data flow pipeline
- **`INICIAR_MEDIAPIPE_SERVER.bat`** - Quick start script for MediaPipe server

### GIF Assets & Lessons
- **`INSTRUCCIONES_GIFS_LOCALES.md`** - GIF assets migration guide
  - How to export GIFs from MongoDB
  - Asset structure requirements
  - Verification and troubleshooting

### API Documentation
- **`inclusing_language_flutter/README.md`** - Flutter app specific documentation
- **`api_dart/README.md`** - Dart API documentation
- **`inclusing_language_flutter/assets/gifs/README.md`** - GIF asset management instructions
