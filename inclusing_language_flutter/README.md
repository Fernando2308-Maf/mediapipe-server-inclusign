# SignLearn - Flutter Version

Una aplicación móvil multiplataforma para aprender lenguaje de señas de forma divertida e interactiva.

## 📱 Sobre la Aplicación

SignLearn es una aplicación educativa diseñada para enseñar lenguaje de señas mediante lecciones interactivas, ejercicios prácticos y un sistema de gamificación que mantiene a los usuarios motivados.

### Características Principales

- 🤟 **Lecciones Interactivas**: Aprende el alfabeto, números y palabras básicas en lenguaje de señas
- ⚡ **Sistema de Experiencia**: Gana puntos XP al completar lecciones
- 🔥 **Rachas Diarias**: Mantén tu motivación con el sistema de rachas
- 📊 **Seguimiento de Progreso**: Visualiza tu avance y estadísticas
- 👤 **Perfiles de Usuario**: Crea tu cuenta o usa modo invitado
- 🎯 **Metas Personalizables**: Establece tus propios objetivos diarios

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.35.7** - Framework multiplataforma
- **Dart 3.9.2** - Lenguaje de programación
- **MongoDB** - Base de datos (Atlas)
- **Railway** - Hosting de API

### Dependencias Principales

```yaml
http: ^1.2.0                      # Cliente HTTP para API
flutter_secure_storage: ^9.0.0   # Almacenamiento seguro
provider: ^6.1.1                  # State management
shared_preferences: ^2.2.2       # Preferencias locales
```

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK 3.0 o superior
- Dart SDK 3.0 o superior
- Android Studio / Xcode (para emuladores)
- Git

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
cd inclusing_language_flutter
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Verificar configuración de Flutter**
```bash
flutter doctor
```

4. **Ejecutar la aplicación**
```bash
# Android
flutter run

# iOS
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/                   # Modelos de datos
│   ├── user_profile.dart     # Modelo local de usuario (UI)
│   ├── lesson.dart           # Modelo local de lección (UI)
│   ├── auth_models.dart      # Modelos de autenticación
│   ├── progress_models.dart  # Modelos de progreso (legacy)
│   └── mongodb_models.dart   # ⭐ Modelos MongoDB (Usuarios, Progresion, Niveles)
├── services/                 # Servicios y lógica de negocio
│   ├── api_service.dart      # Cliente HTTP (Usuarios, Progresion, Niveles)
│   ├── auth_service.dart     # Autenticación
│   ├── lesson_service.dart   # Gestión de niveles y progresión
│   └── storage_service.dart  # Almacenamiento local
├── screens/                  # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   └── lesson_screen.dart    # ⭐ Pantalla de lecciones
├── widgets/                  # Widgets reutilizables
└── utils/                    # Utilidades y constantes
    ├── colors.dart
    └── constants.dart
```

## 🔌 Conexión con la API

La aplicación se conecta a una API REST alojada en Railway:

```dart
https://inclusing-lenguage-api-production.up.railway.app/api
```

### Endpoints Principales

**Autenticación:**
- `POST /auth/register` - Registro de usuarios
- `POST /auth/login` - Inicio de sesión

**Colección: Usuarios**
- `GET /usuarios/{usuarioID}` - Obtener usuario
- Estructura: `{usuarioID, nombre, correo, pass, fechaRegistro}`

**Colección: Progresion**
- `GET /progresion/{usuarioID}` - Obtener progresión del usuario
- `PUT /progresion/{usuarioID}` - Actualizar progresión
- `POST /progresion/completar-nivel` - Completar un nivel
- `POST /progresion/registrar-intento` - Registrar intento
- Estructura: `{usuarioID, nivelActual, nivelesCompletados[], intentos[], estadisticas{}}`

**Colección: Niveles**
- `GET /niveles` - Obtener todos los niveles
- `GET /niveles/{nivelID}` - Obtener nivel por ID
- Estructura: `{nivelID, nombre, maxIntentos, recompensa{puntos}}`

## 📊 Estructura de Colecciones MongoDB

### Colección: Usuarios
```json
{
  "_id": ObjectId("..."),
  "usuarioID": "u123",
  "nombre": "Carlos",
  "correo": "carlos@example.com",
  "pass": "hashed_password",
  "fechaRegistro": "2025-09-20"
}
```

### Colección: Progresion
```json
{
  "_id": ObjectId("..."),
  "usuarioID": "u123",
  "nivelActual": 20,
  "nivelesCompletados": [1, 2, 3, 4, 5, ..., 20],
  "intentos": [
    { "nivel": 5, "resultado": "fallo", "fecha": "2025-09-20" },
    { "nivel": 5, "resultado": "fallo", "fecha": "2025-09-21" },
    { "nivel": 5, "resultado": "exito", "fecha": "2025-09-22" }
  ],
  "estadisticas": {
    "tiempoJugadoMin": 340,
    "totalIntentos": 27,
    "totalExitos": 20
  }
}
```

### Colección: Niveles
```json
{
  "_id": ObjectId("..."),
  "nivelID": 5,
  "nombre": "Nivel_1",
  "maxIntentos": 10,
  "recompensa": {
    "puntos": 50
  }
}
```

**Nota importante:** La aplicación NO utiliza la colección "users". Solo se usan las 3 colecciones: **Usuarios**, **Progresion**, **Niveles**.

## 🎨 Diseño y Tema

La aplicación utiliza un tema oscuro con los siguientes colores:

- **Background**: `#00131F`
- **Card Background**: `#002132`
- **Primary**: `#13B7FF`
- **Secondary**: `#86CBFF`
- **Accent**: `#00ABE8`

## 🔒 Seguridad

- Almacenamiento seguro de tokens con `flutter_secure_storage`
- Contraseñas hasheadas en el backend
- Validación de datos en cliente y servidor
- Timeout de 120 segundos para requests HTTP

## 🧪 Testing

Ejecutar tests:

```bash
flutter test
```

Análisis de código:

```bash
flutter analyze
```

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ⚠️ macOS (requiere configuración adicional)
- ⚠️ Linux (requiere configuración adicional)

## 🔄 Comparación con la Versión .NET MAUI

Esta versión Flutter es una réplica funcional de la aplicación original en .NET MAUI:

| Característica | .NET MAUI | Flutter |
|----------------|-----------|---------|
| Multiplataforma | ✅ | ✅ |
| UI Nativa | ✅ | ✅ |
| Misma API | ✅ | ✅ |
| Mismo Diseño | ✅ | ✅ |
| Hot Reload | ✅ | ✅ |

## 👥 Modo Invitado

Los usuarios pueden explorar la aplicación sin crear una cuenta:
- Acceso limitado a funcionalidades
- Progreso no guardado
- Perfecto para probar la app

## 📝 Notas de Desarrollo

- La aplicación usa `async/await` para operaciones asíncronas
- State management con setState (puede migrarse a Provider/Bloc)
- Navegación con Navigator 1.0
- Responsive design adaptable a diferentes tamaños de pantalla

## 🐛 Problemas Conocidos

- Los warnings de `withOpacity` son por deprecación en Flutter 3.35+ (no crítico)
- Algunos `BuildContext` warnings son esperados en código async (práctica común)

## 🚧 Funcionalidades Futuras

- [ ] Implementación completa de lecciones
- [ ] Ejercicios interactivos con reconocimiento de señas
- [ ] Sistema de insignias y logros
- [ ] Modo offline
- [ ] Notificaciones push
- [ ] Compartir progreso en redes sociales
- [ ] Modo multijugador/competitivo

## 📄 Licencia

Este proyecto fue creado como una réplica de la aplicación InclusingLenguage original en .NET MAUI.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📧 Contacto

Para preguntas o sugerencias:
- Email: soporte@signlearn.com

---

**Hecho con ❤️ para la comunidad sorda**
