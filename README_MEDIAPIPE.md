# 🎯 Sistema de Reconocimiento de Gestos - MediaPipe + Flutter

## 📋 Resumen del Sistema

Este proyecto integra **MediaPipe** con **Flutter** para reconocer gestos de lenguaje de señas en tiempo real usando un modelo de TensorFlow.

### Componentes del Sistema

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Flutter App    │ ───> │ MediaPipe Server │ ───> │  Django API     │
│  (Captura       │      │  (Python)        │      │  (TensorFlow)   │
│   frames)       │      │  Extrae 81       │      │  Predice gesto  │
└─────────────────┘      │  landmarks       │      └─────────────────┘
                         └──────────────────┘
```

---

## 🚀 Inicio Rápido

### 1️⃣ Instalar Dependencias de Python

```bash
cd Inclusign
pip install -r requirements_mediapipe.txt
```

### 2️⃣ Probar MediaPipe (Demo con Webcam)

```bash
python mediapipe_landmark_extractor.py
```

Deberías ver tu webcam con landmarks dibujados en tiempo real.

### 3️⃣ Iniciar el Servidor MediaPipe

```bash
python mediapipe_server.py
```

El servidor se ejecutará en `http://localhost:5000`

### 4️⃣ Probar el Pipeline Completo

```bash
python test_complete_pipeline.py
```

Esto probará el flujo completo: MediaPipe → Django API → Predicción

---

## 📁 Archivos Creados

### Scripts de Python

| Archivo | Descripción |
|---------|-------------|
| `mediapipe_landmark_extractor.py` | Extractor de landmarks usando MediaPipe |
| `mediapipe_server.py` | Servidor Flask para extraer landmarks vía HTTP |
| `test_complete_pipeline.py` | Test del pipeline completo |
| `requirements_mediapipe.txt` | Dependencias de Python |

### Documentación

| Archivo | Descripción |
|---------|-------------|
| `INSTRUCCIONES_MEDIAPIPE_FLUTTER.md` | Guía completa de integración |
| `README_MEDIAPIPE.md` | Este archivo |

### Flutter (Actualizado)

| Archivo | Descripción |
|---------|-------------|
| `lib/screens/gesture_camera_screen.dart` | UI renovada con overlay y historial |
| `lib/services/gesture_recognition_service.dart` | Servicio de comunicación con API |

---

## 🎨 Mejoras en la UI de Flutter

### ✨ Nuevas Funcionalidades

1. **Overlay del Gesto Reconocido**
   - Badge grande sobre la cámara mostrando el gesto actual
   - Animación suave con sombras
   - Color: Primary azul con 90% opacidad

2. **Panel de Información Mejorado**
   - Estado con indicador visual (círculo verde/gris)
   - Nombre del gesto con tipografía grande
   - Ícono de verificación con porcentaje de confianza
   - Top 3 alternativas con bullets

3. **Historial de Gestos**
   - Últimos 10 gestos detectados
   - Chips con diseño moderno
   - Auto-scroll horizontal

4. **Stream de Cámara Optimizado**
   - Manejo robusto de errores
   - Fallback a timer si el stream falla
   - Detección de si MediaPipe está disponible

---

## 🔧 Cómo Usar

### Opción A: Testing con Python (RECOMENDADO)

1. **Iniciar servidor MediaPipe**:
   ```bash
   python mediapipe_server.py
   ```

2. **Desde Flutter, cambiar la URL del servicio**:

   Edita `lib/services/gesture_recognition_service.dart`:

   ```dart
   static const String _baseUrl = 'http://localhost:5000';
   static const String _extractEndpoint = '/extract';
   ```

   Luego modifica el método `sendLandmarks()` para:
   - Enviar frame a MediaPipe Server (`http://localhost:5000/extract`)
   - Recibir landmarks
   - Enviar landmarks a Django API

3. **Ejecutar Flutter**:
   ```bash
   cd inclusing_language_flutter
   flutter pub get
   flutter run -d windows
   ```

### Opción B: Producción (Platform Channels)

Ver `INSTRUCCIONES_MEDIAPIPE_FLUTTER.md` para implementación nativa.

---

## 📊 Formato de Landmarks

### Estructura de Datos

El sistema usa **81 puntos × 3 coordenadas = 243 valores**:

```python
landmarks = [
    # POSE (33 puntos)
    [x, y, z],  # 0: Nariz
    [x, y, z],  # 1: Ojo izq interno
    ...         # hasta 32

    # CARA (6 puntos específicos)
    [x, y, z],  # Índice 1
    [x, y, z],  # Índice 33
    [x, y, z],  # Índice 263
    [x, y, z],  # Índice 61
    [x, y, z],  # Índice 291
    [x, y, z],  # Índice 199

    # MANO IZQUIERDA (21 puntos)
    [x, y, z],  # 0: Muñeca
    [x, y, z],  # 1: Pulgar base
    ...         # hasta 20

    # MANO DERECHA (21 puntos)
    [x, y, z],  # 0: Muñeca
    ...         # hasta 20
]
```

### Envío a API

```python
# Aplanar a lista de 243 valores
flat = landmarks.flatten().tolist()

# Enviar a Django
response = requests.post(
    'https://django-rest-framework-uc05.onrender.com/api/predict/',
    json={'landmarks': flat}
)
```

---

## 🧪 Testing

### Test Rápido (1 Frame)

```bash
python test_complete_pipeline.py quick
```

### Test Completo (Tiempo Real)

```bash
python test_complete_pipeline.py
```

Instrucciones:
- Colócate frente a la cámara
- Asegúrate de tener buena iluminación
- Mueve las manos dentro del campo de visión
- Espera a que se capturen 65 frames
- Verás la predicción en consola y en pantalla

### Verificar Servidor

```bash
curl http://localhost:5000/health
```

---

## 🐛 Troubleshooting

### Error: "No module named mediapipe"

```bash
pip install mediapipe opencv-python
```

### Error: "Cannot open camera"

- Cierra otras aplicaciones que usen la cámara (Zoom, Teams, etc.)
- Verifica permisos de cámara
- Reinicia la terminal

### Landmarks = 0 o None

- Verifica que hay buena iluminación
- Colócate completamente dentro del campo de visión
- Mantén las manos visibles

### API Timeout

La API de Django en Render puede tardar en responder (cold start):
- Primera petición: ~30 segundos
- Peticiones siguientes: <5 segundos

### Flutter no detecta gestos

Verifica que el servidor MediaPipe esté corriendo:

```bash
curl http://localhost:5000/health
```

---

## 📈 Flujo de Datos Completo

### 1. Captura de Frame
```
Flutter Camera → CameraImage (YUV420)
```

### 2. Conversión y Envío
```dart
// Convertir a bytes
Uint8List bytes = convertYUV420toJPEG(image);

// Codificar en base64
String base64Image = base64Encode(bytes);

// Enviar a MediaPipe Server
POST http://localhost:5000/extract
{
  "image": "base64_encoded_data"
}
```

### 3. Procesamiento en Python
```python
# Decodificar imagen
frame = cv2.imdecode(...)

# Procesar con MediaPipe
results = holistic.process(frame)

# Extraer 81 landmarks
landmarks = extract_keypoints(results)  # (81, 3)

# Aplanar a 243 valores
flat = landmarks.flatten().tolist()
```

### 4. Envío a Django
```python
POST https://django-rest-framework-uc05.onrender.com/api/predict/
{
  "landmarks": [243 valores]
}
```

### 5. Predicción
```python
# Django acumula 65 frames
if len(buffer) < 65:
    return {"estado": "esperando 65 frames"}

# Predice con TensorFlow
prediction = model.predict(sequence)

return {
    "gesto": "HOLA",
    "confianza": 0.95,
    "top_3": [...]
}
```

### 6. Actualización de UI
```dart
setState(() {
  _recognizedGesture = result.gesto;
  _confidence = result.confianza;
  _gestureHistory.add(result.gesto);
});
```

---

## 🎯 Próximos Pasos

### Implementación Actual (Testing)

- [x] Crear extractor de landmarks con MediaPipe
- [x] Crear servidor Flask
- [x] Actualizar UI de Flutter
- [x] Integrar con API Django
- [ ] **Probar el sistema completo**

### Implementación Futura (Producción)

- [ ] Platform Channels para Android
- [ ] Optimizar procesamiento de frames
- [ ] Caché de predicciones
- [ ] Modo offline con TFLite
- [ ] Feedback háptico al reconocer gesto

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs de consola
2. Verifica que todos los servidores estén corriendo
3. Consulta `INSTRUCCIONES_MEDIAPIPE_FLUTTER.md`
4. Prueba cada componente por separado

---

**Hecho con ❤️ para Inclusign**

*Última actualización: 2025-11-28*
