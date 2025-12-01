# 🎯 Guía: Reconocimiento de Gestos en Tiempo Real

## 📋 ¿Qué acabamos de hacer?

Hemos integrado tu sistema de reconocimiento de gestos (que ya funcionaba en Python) directamente en la aplicación Flutter. Ahora la app puede reconocer **21 gestos de lenguaje de señas en tiempo real** usando la cámara del dispositivo.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────┐
│   Flutter App       │
│   (Cámara)          │
└──────────┬──────────┘
           │ Captura frames
           │ Convierte a JPEG
           ↓
┌─────────────────────┐
│ MediaPipe Server    │  ← 🆕 Servidor Python Local
│ (localhost:5000)    │
│ - Extrae landmarks  │
│ - 81 puntos × 3     │
│ - = 243 valores     │
└──────────┬──────────┘
           │ Landmarks
           ↓
┌─────────────────────┐
│   Django API        │
│ (Render - Online)   │
│ - Acumula 65 frames │
│ - Predice gesto     │
│ - TensorFlow/Keras  │
└──────────┬──────────┘
           │ Predicción
           ↓
┌─────────────────────┐
│   Flutter UI        │
│ - Muestra gesto     │
│ - Confianza %       │
│ - Top 3 opciones    │
│ - Historial         │
└─────────────────────┘
```

---

## 🚀 Cómo Usar el Sistema

### Paso 1: Iniciar el Servidor MediaPipe

**Opción A - Usando el script (MÁS FÁCIL):**
```bash
# Haz doble clic en el archivo:
INICIAR_MEDIAPIPE_SERVER.bat
```

**Opción B - Manualmente:**
```bash
cd "Proyecto integrador - copia\Proyecto integrador - copia"
.venv\Scripts\activate
python mediapipe_server.py
```

Verás:
```
🚀 MediaPipe Server - Inclusign
============================================================
Endpoints disponibles:
  GET  / .................. Health check
  GET  /health ............ Verifica MediaPipe
  POST /extract ........... Extrae landmarks
  POST /extract-and-predict  Extrae y predice

Servidor corriendo en: http://localhost:5000
============================================================
```

**✅ El servidor DEBE estar corriendo antes de iniciar Flutter!**

---

### Paso 2: Ejecutar la Aplicación Flutter

```bash
cd inclusing_language_flutter

# Ejecutar en Windows
flutter run -d windows

# O en Android (con emulador abierto)
flutter run -d android

# O en cualquier dispositivo conectado
flutter run
```

---

### Paso 3: Usar el Reconocimiento de Gestos

1. **Abre la app Flutter**
2. **Navega al apartado de cámara** (Gesture Recognition)
3. **Presiona "Iniciar"**
4. **Colócate frente a la cámara**:
   - Asegúrate de que todo tu cuerpo esté visible
   - Mantén buena iluminación
   - Realiza un gesto de lenguaje de señas

5. **Espera a que se acumulen 65 frames** (~30-40 segundos)
6. **¡Verás el gesto reconocido en pantalla!**

---

## 🎨 Interfaz de Usuario

### Vista de Cámara
- **Vista en vivo** de la cámara
- **Overlay grande** mostrando el gesto actual
- **Borde azul** alrededor del frame

### Panel de Información
- **Estado**: Indicador verde/gris de detección activa
- **Gesto Reconocido**: Nombre del gesto en grande
- **Confianza**: Porcentaje de certeza (ej: 95.2%)
- **Top 3 Alternativas**: Otras posibilidades
- **Historial**: Últimos 10 gestos detectados

### Controles
- **Botón Iniciar/Detener**: Comienza o para la detección

---

## 🎯 21 Gestos Reconocibles

El sistema puede reconocer estos gestos:

| # | Gesto Español | Traducción |
|---|---------------|------------|
| 1 | buenas_noches | Good night |
| 2 | buenos_dias | Good morning |
| 3 | como_estas | How are you |
| 4 | cual_es_tu_nombre | What is your name |
| 5 | cuidate_mucho | Take care |
| 6 | entiendo | I understand |
| 7 | eres_sordo | Are you deaf |
| 8 | gracias | Thank you |
| 9 | hola | Hello |
| 10 | hola_gusto_conocerte | Hello, nice to meet you |
| 11 | mi_nombre_es | My name is |
| 12 | no | No |
| 13 | no_entiendo | I don't understand |
| 14 | oyente | Hearing person |
| 15 | podemos_hablar | Can we talk |
| 16 | porfavor | Please |
| 17 | porque | Why |
| 18 | puedo_ayudarte | Can I help you |
| 19 | quien | Who |
| 20 | si | Yes |
| 21 | sordo | Deaf |

---

## 🔧 Archivos Modificados/Creados

### Archivos Flutter Modificados

1. **`lib/services/gesture_recognition_service.dart`**
   - ✅ Agregado: `sendImageForRecognition()` - Envía JPEG a MediaPipe
   - ✅ Modificado: URLs para usar servidor local
   - ✅ Flujo completo: Imagen → MediaPipe → Django → Respuesta

2. **`lib/screens/gesture_camera_screen.dart`**
   - ✅ Removido: Código de ML Kit (innecesario)
   - ✅ Agregado: `_convertCameraImageToJpeg()` - Convierte frames a JPEG
   - ✅ Simplificado: Stream de cámara más eficiente
   - ✅ UI: Mensajes de error más claros

3. **`pubspec.yaml`**
   - ✅ Agregado: `image: ^4.0.17` (procesamiento de imágenes)
   - ✅ Removido: `google_mlkit_pose_detection` y `google_mlkit_face_detection`

### Archivos Python Copiados

4. **`Proyecto integrador - copia/Proyecto integrador - copia/mediapipe_server.py`**
   - Servidor Flask con MediaPipe
   - Puerto: 5000
   - Endpoints: `/extract`, `/extract-and-predict`, `/health`

5. **`Proyecto integrador - copia/Proyecto integrador - copia/mediapipe_landmark_extractor.py`**
   - Clase para extraer landmarks con MediaPipe
   - 81 puntos: pose (33) + cara (6) + manos (21+21)

### Archivos Nuevos

6. **`INICIAR_MEDIAPIPE_SERVER.bat`**
   - Script para iniciar el servidor fácilmente
   - Activa el venv automáticamente

7. **`GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md`**
   - Este archivo - documentación completa

---

## 📊 Flujo de Datos Técnico

### 1. Captura de Frame
```dart
// Flutter captura frame de cámara (YUV420)
CameraImage image = ...;
```

### 2. Conversión a JPEG
```dart
// Convierte YUV420 → RGB → JPEG
Uint8List jpegBytes = await _convertCameraImageToJpeg(image);
// Tamaño: ~50-150 KB por frame
```

### 3. Envío a MediaPipe Server
```dart
// POST http://localhost:5000/extract
{
  "image": "base64_encoded_jpeg_data"
}
```

### 4. Extracción de Landmarks
```python
# MediaPipe procesa la imagen
results = holistic.process(frame)

# Extrae 81 landmarks × 3 coordenadas = 243 valores
landmarks = extract_keypoints(results)
```

### 5. Envío a Django API
```python
# POST https://django-rest-framework-uc05.onrender.com/api/predict/
{
  "landmarks": [243 float values]
}
```

### 6. Acumulación y Predicción
```python
# Django acumula frames
if len(buffer) < 65:
    return {"estado": "esperando 65 frames"}

# Cuando tiene 65 frames, predice
prediction = model.predict(sequence)

return {
    "gesto": "hola",
    "confianza": 0.95,
    "top_3": [
        {"gesto": "hola", "prob": 0.95},
        {"gesto": "buenos_dias", "prob": 0.03},
        {"gesto": "gracias", "prob": 0.01}
    ]
}
```

### 7. Actualización de UI
```dart
setState(() {
  _recognizedGesture = result.gesto;
  _confidence = result.confianza;
  _top3 = result.top3;
});
```

---

## 🐛 Solución de Problemas

### Problema 1: "Error: MediaPipe server no responde"

**Causa:** El servidor MediaPipe no está corriendo.

**Solución:**
1. Abre una terminal
2. Ejecuta `INICIAR_MEDIAPIPE_SERVER.bat`
3. Espera a ver el mensaje "Servidor corriendo en: http://localhost:5000"
4. Reinicia la app Flutter

---

### Problema 2: "ModuleNotFoundError: No module named 'mediapipe'"

**Causa:** Faltan dependencias de Python.

**Solución:**
```bash
cd "Proyecto integrador - copia\Proyecto integrador - copia"
.venv\Scripts\activate
pip install mediapipe opencv-python flask flask-cors numpy
```

---

### Problema 3: Landmarks no se detectan

**Causa:** Mala iluminación o cuerpo no visible.

**Solución:**
- ✅ Asegúrate de tener buena luz
- ✅ Colócate completamente dentro del frame de la cámara
- ✅ Mantén las manos visibles
- ✅ No uses ropa del mismo color que el fondo

---

### Problema 4: API Django tarda mucho (primera vez)

**Causa:** Django API en Render tiene "cold start".

**Solución:**
- ⏱️ Primera petición puede tardar 30-60 segundos
- ✅ Espera pacientemente
- ✅ Peticiones subsecuentes serán más rápidas (<5 segundos)

---

### Problema 5: Error de conversión de imagen

**Causa:** Problema con el paquete `image`.

**Solución:**
```bash
cd inclusing_language_flutter
flutter clean
flutter pub get
flutter run
```

---

## 📈 Rendimiento Esperado

### Velocidad
- **Captura de frames:** ~2 FPS (limitado intencionalmente)
- **Procesamiento MediaPipe:** ~50-100ms por frame
- **Predicción Django (tras 65 frames):** ~2-5 segundos
- **Total para reconocimiento:** ~40-50 segundos desde inicio

### Precisión
- **Modelo:** 94.6% de precisión en dataset de prueba
- **Tiempo real:** Variable según condiciones de luz y posición
- **Mejores resultados:** Buena iluminación + cuerpo completo visible

### Recursos
- **RAM (Flutter):** ~200-300 MB
- **RAM (MediaPipe Server):** ~500-800 MB
- **CPU (MediaPipe):** 20-40% de un core
- **Ancho de banda:** ~1-2 MB/segundo (durante detección)

---

## 🎓 Cómo Funciona el Modelo

### Entrada
- **65 frames** consecutivos
- Cada frame tiene **243 valores** (81 landmarks × 3 coordenadas)
- Total: **65 × 243 = 15,795 valores** por predicción

### Procesamiento
1. **Normalización:** Z-score (x - mean) / std
2. **Reshape:** (1, 65, 243) para TensorFlow
3. **Red LSTM Bidireccional:** Captura patrones temporales
4. **Softmax:** Salida de 21 probabilidades (una por gesto)

### Salida
- **Gesto:** El más probable de los 21
- **Confianza:** Probabilidad del gesto predicho (0-1)
- **Top 3:** Los 3 gestos más probables con sus probabilidades

---

## 🔒 Seguridad y Privacidad

- ✅ **Imágenes temporales:** Los frames se procesan y descartan inmediatamente
- ✅ **Sin almacenamiento:** No se guardan imágenes ni videos
- ✅ **Solo landmarks:** Django API solo recibe coordenadas numéricas, no imágenes
- ✅ **Servidor local:** MediaPipe corre en tu computadora, no envía datos a internet
- ⚠️ **Django en la nube:** Landmarks se envían a Render (pero son solo números, no imágenes)

---

## 🚧 Limitaciones Actuales

1. **Requiere servidor local:**
   - MediaPipe server debe correr en localhost
   - No funciona en producción sin servidor Python

2. **Latencia:**
   - Necesita acumular 65 frames (~40 segundos)
   - No es instantáneo como detección de objetos

3. **Condiciones de captura:**
   - Requiere buena iluminación
   - Cuerpo completo debe estar visible
   - Fondo preferiblemente uniforme

4. **Solo 21 gestos:**
   - Limitado a los gestos entrenados
   - No reconoce nuevos gestos sin reentrenar modelo

---

## 🔮 Mejoras Futuras Posibles

### Corto Plazo
- [ ] Agregar indicador visual de progreso (X/65 frames)
- [ ] Mostrar visualización de landmarks en pantalla
- [ ] Agregar sonido cuando se reconoce un gesto
- [ ] Modo de práctica: Usuario intenta hacer un gesto específico

### Mediano Plazo
- [ ] Integrar MediaPipe directamente en Flutter (sin servidor)
  - Requiere platform channels (Android/iOS)
  - Más complejo pero más rápido
- [ ] Reducir frames necesarios de 65 a 30
  - Reentrenar modelo
  - Reconocimiento más rápido

### Largo Plazo
- [ ] Expandir a más gestos (frases completas)
- [ ] Reconocimiento de gestos continuos (múltiples en secuencia)
- [ ] Modo traductor en tiempo real
- [ ] Entrenamiento personalizado por usuario

---

## 📞 Contacto y Soporte

Si tienes problemas:

1. **Revisa los logs de consola** - Flutter y MediaPipe server
2. **Verifica que el servidor esté corriendo** - `curl http://localhost:5000/health`
3. **Consulta esta guía** - Solución de problemas
4. **Revisa los archivos de documentación:**
   - `README_MEDIAPIPE.md`
   - `INSTRUCCIONES_MEDIAPIPE_FLUTTER.md`

---

## ✅ Checklist de Verificación

Antes de reportar un problema, verifica:

- [ ] El servidor MediaPipe está corriendo (`INICIAR_MEDIAPIPE_SERVER.bat`)
- [ ] Puedes acceder a `http://localhost:5000/health` en el navegador
- [ ] Flutter tiene permiso de cámara
- [ ] La cámara funciona en otras aplicaciones
- [ ] Estás usando buena iluminación
- [ ] Tu cuerpo completo está visible en el frame
- [ ] Has esperado a que se acumulen 65 frames
- [ ] La conexión a internet funciona (para Django API)

---

**¡Disfruta del reconocimiento de gestos en tiempo real! 🎉**

*Última actualización: 2025-12-01*
