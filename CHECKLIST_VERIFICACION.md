# ✅ Checklist de Verificación - Sistema de Reconocimiento de Gestos

## 📋 Antes de Usar

### ✅ Instalación y Configuración

- [ ] **Python venv configurado**
  ```bash
  cd "Proyecto integrador - copia\Proyecto integrador - copia"
  .venv\Scripts\python --version
  # Deberías ver: Python 3.x.x
  ```

- [ ] **Dependencias Python instaladas**
  ```bash
  cd "Proyecto integrador - copia\Proyecto integrador - copia"
  .venv\Scripts\pip list | findstr "mediapipe flask opencv"
  # Deberías ver: mediapipe, flask, flask-cors, opencv-python
  ```

- [ ] **Flutter configurado**
  ```bash
  flutter doctor
  # Deberías ver: [✓] Flutter, [✓] Windows, etc.
  ```

- [ ] **Dependencias Flutter instaladas**
  ```bash
  cd inclusing_language_flutter
  flutter pub get
  # Deberías ver: Got dependencies!
  ```

---

## 🖥️ Verificación del Servidor MediaPipe

### ✅ Servidor puede iniciar

- [ ] **Script BAT existe**
  ```
  INICIAR_MEDIAPIPE_SERVER.bat está en la carpeta raíz
  ```

- [ ] **Servidor inicia sin errores**
  ```bash
  # Ejecuta: INICIAR_MEDIAPIPE_SERVER.bat
  # Deberías ver:
  🚀 MediaPipe Server - Inclusign
  Servidor corriendo en: http://localhost:5000
  ```

- [ ] **Servidor responde a health check**
  ```bash
  curl http://localhost:5000/health
  # Deberías ver:
  {"status": "healthy", "mediapipe": "initialized"}
  ```

- [ ] **Endpoint de extracción funciona**
  ```bash
  curl http://localhost:5000/
  # Deberías ver información de endpoints disponibles
  ```

---

## 📱 Verificación de Flutter

### ✅ Compilación

- [ ] **Código analiza sin errores críticos**
  ```bash
  cd inclusing_language_flutter
  flutter analyze
  # Pueden haber warnings (print, withOpacity) pero NO errores
  ```

- [ ] **App compila y se ejecuta**
  ```bash
  flutter run -d windows
  # La app debería abrirse sin crashes
  ```

### ✅ Permisos

- [ ] **Permiso de cámara otorgado**
  - Al abrir la pantalla de gestos, Windows pregunta por permiso
  - Haz clic en "Permitir"

- [ ] **Cámara funciona en otras apps**
  - Abre Windows Camera o cualquier otra app
  - Verifica que la cámara capture imagen

---

## 🎥 Verificación de Reconocimiento

### ✅ Flujo completo

- [ ] **Pantalla de gestos se abre**
  - Navega a "Gesture Recognition" o "Reconocimiento de Gestos"
  - La pantalla muestra vista de cámara

- [ ] **Botón "Iniciar" funciona**
  - Presiona "Iniciar" o "Start"
  - Estado cambia a indicador verde

- [ ] **Frames se capturan**
  - En los logs de Flutter deberías ver:
  ```
  ✅ Primera imagen convertida: XXXXX bytes
  📤 Enviando imagen a MediaPipe server...
  ```

- [ ] **MediaPipe procesa frames**
  - En los logs del servidor Python deberías ver peticiones POST

- [ ] **Landmarks se extraen**
  - En logs de Flutter:
  ```
  ✅ Landmarks extraídos: 243 valores
  ```

- [ ] **Django API recibe landmarks**
  - En logs de Flutter:
  ```
  ⏳ Frame enviado: X
  # O después de 65 frames:
  ✅ Gesto reconocido: hola
  ```

- [ ] **UI se actualiza**
  - Overlay grande muestra nombre del gesto
  - Panel inferior muestra confianza y top 3

---

## 🎯 Prueba de Gestos

### ✅ Test de reconocimiento

Prueba al menos 3 gestos diferentes:

- [ ] **Gesto 1: "hola"**
  - Realiza el gesto de saludo
  - Espera ~40 segundos
  - Verifica que aparezca "hola" en pantalla

- [ ] **Gesto 2: "gracias"**
  - Realiza el gesto de gracias
  - Espera acumulación de frames
  - Verifica reconocimiento

- [ ] **Gesto 3: "si"**
  - Realiza el gesto de afirmación
  - Verifica que se detecte correctamente

---

## 🔍 Logs y Debugging

### ✅ Logs importantes

- [ ] **Flutter console muestra:**
  ```
  🎥 Intentando iniciar stream de cámara...
  ✅ Stream de cámara iniciado
  ✅ Primera imagen convertida: XXXXX bytes
  📤 Enviando imagen a MediaPipe server...
  ✅ Landmarks extraídos: 243 valores
  ⏳ Frame enviado: 1
  ⏳ Frame enviado: 2
  ...
  ✅ Gesto reconocido: hola
  ```

- [ ] **MediaPipe server muestra:**
  ```
  127.0.0.1 - - [fecha] "POST /extract HTTP/1.1" 200 -
  ```

- [ ] **No hay errores en ninguna consola:**
  - ❌ No debe haber "Error 500"
  - ❌ No debe haber "Connection refused"
  - ❌ No debe haber "Timeout"

---

## 📊 Rendimiento

### ✅ Métricas esperadas

- [ ] **Velocidad de captura:** ~2 frames/segundo
  - Verifica en logs: Frame 1, Frame 2, ... cada ~0.5 segundos

- [ ] **Tiempo total:** ~40-50 segundos desde inicio hasta predicción
  - Mide con cronómetro

- [ ] **Tamaño de imagen:** ~50-150 KB por frame
  - Verifica en logs: "Primera imagen convertida: XXXXX bytes"

- [ ] **RAM usada:**
  - Flutter: ~200-300 MB
  - MediaPipe server: ~500-800 MB

---

## 🐛 Troubleshooting Checklist

### Si algo falla, verifica:

- [ ] **Servidor MediaPipe está corriendo**
  ```bash
  curl http://localhost:5000/health
  ```

- [ ] **Puerto 5000 no está ocupado**
  ```bash
  netstat -ano | findstr :5000
  # Solo debería mostrar el proceso de Python
  ```

- [ ] **Flutter tiene permisos de cámara**
  - Configuración de Windows > Privacidad > Cámara
  - Permitir apps de escritorio

- [ ] **Buena iluminación en la habitación**
  - Luz natural o artificial fuerte
  - Sin contraluz

- [ ] **Cuerpo completo visible en frame**
  - Cabeza, torso, brazos, manos
  - No cortado por los bordes

- [ ] **Internet funciona (para Django API)**
  ```bash
  ping django-rest-framework-uc05.onrender.com
  ```

---

## ✅ Estado Final

Si todos los checks anteriores pasan:

- [x] ✅ Sistema completamente funcional
- [x] ✅ Servidor MediaPipe operativo
- [x] ✅ Flutter capturando y procesando frames
- [x] ✅ Django API prediciendo gestos
- [x] ✅ UI mostrando resultados correctamente

**🎉 ¡Tu sistema de reconocimiento de gestos está listo para usar!**

---

## 📞 Si Necesitas Ayuda

1. Revisa `GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md` - Sección "Solución de Problemas"
2. Verifica logs en ambas consolas (Flutter y MediaPipe)
3. Consulta `RESUMEN_INTEGRACION_COMPLETA.md` para detalles técnicos

---

**Fecha de verificación:** __________

**Resultado:** ⬜ Todo funciona ⬜ Problemas encontrados

**Notas:**
_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________
