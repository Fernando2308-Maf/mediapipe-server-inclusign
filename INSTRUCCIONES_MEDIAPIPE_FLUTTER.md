# 🎯 Integración de MediaPipe con Flutter para Reconocimiento de Gestos

## 📋 Estado Actual

### ✅ Lo que ya está implementado:

1. **Backend Django (Render)**
   - Endpoint: `https://django-rest-framework-uc05.onrender.com/api/predict/`
   - Recibe 243 valores (81 puntos × 3 coordenadas)
   - Acumula 65 frames en buffer
   - Retorna predicción del gesto con confianza

2. **Frontend Flutter (MEJORADO)**
   - UI completamente renovada con:
     - Overlay del gesto reconocido sobre la cámara
     - Panel de información con confianza y top 3 alternativas
     - Historial de gestos detectados
     - Indicador visual de estado (detectando/detenido)
   - Stream de cámara optimizado
   - Manejo de errores robusto

### ⚠️ Problema Actual

**flutter_mediapipe** tiene limitaciones y no está siendo correctamente utilizado para extraer los 81 landmarks.

## 🔧 Soluciones Disponibles

### Opción 1: Servicio HTTP Intermedio con Python (RECOMENDADO PARA TESTING)

Usa el script `mediapipe_landmark_extractor.py` que creé para ti.

#### Instalación:

```bash
pip install opencv-python mediapipe numpy
```

#### Ejecución:

```bash
# Demo con webcam
python mediapipe_landmark_extractor.py

# Procesar una imagen
python mediapipe_landmark_extractor.py ruta/a/imagen.jpg
```

#### Crear un servidor HTTP simple:

```python
# mediapipe_server.py
from flask import Flask, request, jsonify
from mediapipe_landmark_extractor import MediaPipeLandmarkExtractor
import cv2
import numpy as np
import base64

app = Flask(__name__)
extractor = MediaPipeLandmarkExtractor()

@app.route('/extract', methods=['POST'])
def extract_landmarks():
    try:
        # Recibir imagen en base64
        data = request.json
        image_data = base64.b64decode(data['image'])

        # Convertir a numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        # Procesar
        landmarks, _, _ = extractor.process_frame(frame)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        return jsonify({
            'landmarks': flat_landmarks,
            'success': True
        })
    except Exception as e:
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Instalar Flask:
```bash
pip install flask
```

Ejecutar:
```bash
python mediapipe_server.py
```

Luego desde Flutter, envías frames a `http://localhost:5000/extract` y este te devuelve los landmarks.

---

### Opción 2: Implementar MediaPipe Nativo en Flutter (SOLUCIÓN FINAL)

Para una solución en producción, necesitas usar **Platform Channels** para llamar a MediaPipe nativo.

#### Para Android:

1. **Agregar dependencias** en `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.mediapipe:tasks-vision:0.10.0'
}
```

2. **Crear clase Kotlin** en `android/app/src/main/kotlin/.../MediaPipeHandler.kt`:

```kotlin
package com.example.inclusing_language_flutter

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaPipeHandler : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mediapipe_channel")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "extractLandmarks" -> {
                // Implementar extracción de landmarks
                val imageBytes = call.argument<ByteArray>("image")
                // ... proceso con MediaPipe
                result.success(landmarks)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

3. **Registrar en MainActivity**:

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine
            .plugins
            .add(MediaPipeHandler())
    }
}
```

4. **Usar desde Flutter**:

```dart
import 'package:flutter/services.dart';

class MediaPipeService {
  static const platform = MethodChannel('mediapipe_channel');

  Future<List<double>> extractLandmarks(Uint8List imageBytes) async {
    try {
      final result = await platform.invokeMethod('extractLandmarks', {
        'image': imageBytes,
      });
      return List<double>.from(result);
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
```

---

### Opción 3: Usar tflite_flutter con el modelo de MediaPipe (ALTERNATIVA)

Puedes correr el modelo MediaPipe Holistic directamente en Flutter usando `tflite_flutter`.

1. Descargar modelos:
   - [Pose Landmark](https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task)
   - [Hand Landmark](https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task)
   - [Face Landmark](https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task)

2. Agregar a `pubspec.yaml`:

```yaml
dependencies:
  tflite_flutter: ^0.10.0
  image: ^4.0.0
```

3. Colocar modelos en `assets/models/`

4. Implementar inferencia en Flutter (complejo, requiere post-procesamiento)

---

## 🚀 Recomendación Inmediata

### Para Testing Rápido:

1. **Ejecuta el script Python** para verificar que tu modelo funciona:
```bash
python mediapipe_landmark_extractor.py
```

2. **Verifica la salida**: Deberías ver 243 valores y landmarks dibujados en tiempo real

3. **Crea el servidor Flask** (código arriba) para probar la integración completa:
   - Python extrae landmarks de la cámara
   - Flutter envía frames al servidor Python
   - Python retorna landmarks
   - Flutter envía landmarks a Django
   - Django retorna predicción

### Flujo Completo de Testing:

```
[Flutter App]
    ↓ (captura frame)
    ↓
[Python Server - MediaPipe] (localhost:5000/extract)
    ↓ (retorna 243 landmarks)
    ↓
[Flutter App]
    ↓ (envía landmarks)
    ↓
[Django API - TensorFlow] (Render)
    ↓ (retorna predicción)
    ↓
[Flutter App - UI actualizada]
```

---

## 📝 Siguiente Paso

**¿Qué quieres hacer primero?**

1. **Testing con Python**: Verificar que MediaPipe funciona correctamente
2. **Servidor Flask**: Crear el puente Python-Flutter para pruebas
3. **Platform Channels**: Implementación nativa para producción
4. **tflite_flutter**: Solución 100% Flutter (más complejo)

---

## 🐛 Troubleshooting

### Error: "No module named mediapipe"
```bash
pip install mediapipe opencv-python numpy
```

### Error: "Cannot open camera"
- Verifica permisos de cámara
- Cierra otras apps que usen la cámara
- Reinicia la terminal

### Landmarks = 0 o None
- Asegúrate que hay buena iluminación
- Colócate frente a la cámara con todo el cuerpo visible
- Mueve las manos dentro del campo de visión

---

## 📊 Formato de Landmarks

```python
# Estructura exacta que espera tu modelo:
landmarks = [
    # Pose (33 puntos × 3)
    [x, y, z],  # Punto 0: Nariz
    [x, y, z],  # Punto 1: Ojo izquierdo interno
    # ... hasta punto 32

    # Cara (6 puntos × 3) - Índices específicos de Face Mesh
    [x, y, z],  # Índice 1
    [x, y, z],  # Índice 33
    [x, y, z],  # Índice 263
    [x, y, z],  # Índice 61
    [x, y, z],  # Índice 291
    [x, y, z],  # Índice 199

    # Mano Izquierda (21 puntos × 3)
    [x, y, z],  # Punto 0: Muñeca
    [x, y, z],  # Punto 1: Pulgar base
    # ... hasta punto 20

    # Mano Derecha (21 puntos × 3)
    [x, y, z],  # Punto 0: Muñeca
    # ... hasta punto 20
]

# Total: 81 puntos × 3 coordenadas = 243 valores
# Para enviar a API: landmarks.flatten().tolist()
```

---

**Hecho con ❤️ para Inclusign**
