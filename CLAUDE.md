# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inclusign** is a Flutter mobile app for learning sign language through interactive lessons. It connects to a Node.js/Express REST API backed by MongoDB Atlas.

**Repository Structure:**
- `inclusing_language_flutter/` — Flutter app (primary client)
- `api_node/` — Node.js/Express API (deployed on Vercel, **current production**)
- `api_dart/` — Dart/Shelf REST API (local dev alternative)
- `django-rest-framework/` — Django API with TensorFlow gesture classification

**Production Architecture:**
```
[Flutter App] <--> [Node API (Vercel)] <--> [MongoDB Atlas]
     |
     +-- Local GIF Assets (assets/gifs/)

Gesture Recognition Pipeline:
[Flutter Camera] → [MediaPipe Server (Flask)] → [Django API (TensorFlow)] → Prediction
                    81 landmarks (243 values)     65-frame sequence
```

## Commands

```bash
# Flutter app
cd inclusing_language_flutter
flutter pub get
flutter run -d android          # Physical device
flutter run -d windows          # Windows desktop
flutter analyze                 # Lint
flutter test                    # Run tests
flutter build apk --release     # Build release APK
flutter clean && flutter pub get # Reset build

# Node API (local dev)
cd api_node
npm install
npm start                       # http://localhost:5246

# Dart API (local dev alternative)
cd api_dart
dart pub get
dart run bin/server.dart        # http://localhost:5246
dart analyze

# MediaPipe gesture server
pip install -r requirements_mediapipe.txt
python mediapipe_server.py      # http://localhost:5000
```

**Firebase is required** — `main.dart` calls `Firebase.initializeApp()` at startup. The `google-services.json` must be present in `android/app/`. Without it, the app crashes on launch.

## Configuration

**Production API** (`inclusing_language_flutter/lib/utils/constants.dart`):
```dart
static const String baseUrl = 'https://despliegeapiinclusign.vercel.app/api'; // Vercel
// Local dev: 'http://localhost:5246/api'
// Android emulator: 'http://10.0.2.2:5246/api'
```

**Node API** — create `api_node/.env`:
```
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
DATABASE_NAME=inclusign
PORT=5246
```

**Dart API** — create `api_dart/.env`:
```
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
DATABASE_NAME=inclusign
PORT=5246
```

**Request timeout** is 3 minutes (`AppConstants.requestTimeout`) due to MongoDB Atlas cold starts on the free tier.

**Lint suppressions** (`analysis_options.yaml`): `withOpacity` deprecation warnings, `use_build_context_synchronously`, `avoid_web_libraries_in_flutter`, and `avoid_print` are all intentionally suppressed.

## CI/CD

GitHub Actions (`.github/workflows/build-apk.yml`) runs on every push to `main`/`master`:
1. `flutter analyze` (lint gate)
2. `flutter build apk --release`
3. Uploads APK as artifact and creates a versioned GitHub Release (`v1.0.<run_number>`)

Vercel auto-deploys `api_node/` on push. Config in `api_node/vercel.json`.

## Architecture

### MongoDB Collections

| Collection | Key Fields | Notes |
|---|---|---|
| `Usuarios` | `usuarioID`, `correo`, `pass` | PK is `usuarioID` (string), not email |
| `Progresion` | `usuarioID`, `nivelActual`, `nivelesCompletados[]`, `experienciaTotal` | Progress tracking |
| `Niveles` | `nivelID`, `nombre`, `maxIntentos` | Static lesson metadata |
| `Abecedario` | `letra`, `contenido` | GIFs no longer served — use local assets |
| `Gestos` | `nombre`, `contenido` | GIFs no longer served — use local assets |

### GIF Assets (Critical)

GIFs are **local Flutter assets** (migrated from MongoDB to fix timeout issues):
- `assets/gifs/abecedario/` — 27 files: `A.gif`...`Z.gif`, `Ñ.gif` (uppercase)
- `assets/gifs/gestos/` — 21 files: `HOLA.gif`, `BUENOS_DIAS.gif` etc. (uppercase + underscores)
- `assets/gifs/numeros/` — 10 files: `0.gif`...`9.gif`
- `assets/ml/` — ML model assets for on-device inference

Loaded via `rootBundle.load()` in `lib/data/lesson_data.dart`. If lessons show emoji placeholders, GIF files are missing or misnamed.

### Flutter Services (Singletons)

All services use factory singleton pattern (`static final _instance`):

- **`ApiService`** — all HTTP calls via `_makeRequest(method, endpoint, body?, headers?)`
- **`AuthService`** — authentication state; stores `usuario_id` in `flutter_secure_storage`; handles Google Sign-In via `google_sign_in` + Firebase
- **`LessonService`** — bridges local lesson data with remote progress; `getUsuarioID()` has migration fallback (email → `usuario_id` lookup)
- **`StorageService`** — wrapper for `flutter_secure_storage` + `shared_preferences`; must call `init()` before use (done in `main.dart`)
- **`ThemeService`** — light/dark theme toggle; `InclusignApp` listens to it via `ChangeNotifier`
- **`HybridGestureRecognitionService`** — gesture recognition that falls back between on-device and server-side inference

### Authentication

Two login methods:
1. Email/password → API → returns `usuarioID` + Base64 token
2. Google Sign-In → `AuthService.signInWithGoogle()` → `ApiService.registerWithGoogle()` → same flow

Guest mode: email `guest@inclusign.com` — no progress saved, skips API calls.

Stored keys in secure storage: `user_token`, `user_email`, `usuario_id`, `is_guest`, `login_method`.

### Lesson Completion Flow

1. `lesson_screen.dart` calls `LessonService().registrarIntento(usuarioID, nivel, exito)`
2. Then calls `LessonService().completarNivel(usuarioID, nivel, exito, xp)` — awards 25 XP (5+10+10)
3. `LessonService` → `ApiService._makeRequest()` → API → MongoDB updates `Progresion`

### Gesture Recognition (Experimental)

1. Flutter camera → JPEG base64 → `POST /extract` on MediaPipe server (localhost:5000)
2. MediaPipe returns 243 landmarks (81 points × 3 coords)
3. Django API buffers frames → returns `{"estado": "esperando N frames"}` until 65 frames
4. TensorFlow model predicts gesture → `{"gesto": "HOLA", "confianza": 0.95}`

Django API cold starts ~30s on Render free tier.

### API Route Structure

Both `api_node/` and `api_dart/` expose the same endpoints, all mounted at `/api/<name>`:
- `auth` — `POST /register`, `POST /login`
- `progresion` — GET/PUT progress, `POST /completar-nivel`, `POST /registrar-intento`
- `usuarios` — `GET /:usuarioID`, `GET /by-email/:email`, `PUT /:usuarioID`
- `niveles`, `abecedario`, `gestos` — read-only metadata

Node API uses MongoDB driver directly; Dart API uses `mongo_dart`. Both connect to the same Atlas cluster.

## Key Constants

- **Lessons:** 58 total (27 alphabet + 10 numbers + 21 gestures)
- **XP per lesson:** 25 (3 exercises: 5 + 10 + 10)
- **Landmark count:** 81 points = 243 values (33 pose + 6 face + 21 left + 21 right hand)
- **Sequence length for prediction:** 65 frames
- **Gesture classes:** 21

## Known Issues

- `withOpacity` deprecation warnings in Flutter 3.35+ (suppressed in `analysis_options.yaml`)
- CORS set to `*` in both APIs — restrict for production
- Passwords hashed with SHA-256 (not bcrypt)
- MongoDB Atlas M0 free tier causes cold start latency; 3-minute timeout is intentional
