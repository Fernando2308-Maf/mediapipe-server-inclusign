# 🚀 INICIO RÁPIDO - Reconocimiento de Gestos

## ⚡ Cómo Empezar en 3 Pasos

### 1️⃣ Inicia el Servidor MediaPipe
```bash
# Haz doble clic en:
INICIAR_MEDIAPIPE_SERVER.bat
```

✅ Espera a ver: `Servidor corriendo en: http://localhost:5000`

---

### 2️⃣ Ejecuta la Aplicación Flutter
```bash
cd inclusing_language_flutter
flutter run -d windows
```

✅ Espera a que la app se abra

---

### 3️⃣ Usa el Reconocimiento de Gestos

1. En la app, ve a **"Reconocimiento de Gestos"** o **"Gesture Recognition"**
2. Presiona el botón **"Iniciar"** o **"Start"**
3. Colócate frente a la cámara con:
   - ✅ Todo tu cuerpo visible
   - ✅ Buena iluminación
   - ✅ Manos dentro del frame
4. Realiza un gesto de lenguaje de señas lentamente
5. Espera ~40 segundos (la app acumula 65 frames)
6. **¡Verás el gesto reconocido en pantalla!** 🎉

---

## 🎯 21 Gestos que Puedes Hacer

- **Saludos:** hola, buenos_dias, buenas_noches
- **Cortesía:** gracias, porfavor, cuidate_mucho
- **Conversación:** como_estas, cual_es_tu_nombre, mi_nombre_es
- **Comprensión:** entiendo, no_entiendo
- **Identidad:** sordo, oyente, eres_sordo
- **Preguntas:** quien, porque, podemos_hablar
- **Básicos:** si, no
- **Ayuda:** puedo_ayudarte, hola_gusto_conocerte

---

## ❓ ¿Problemas?

### El servidor no inicia
```bash
cd "Proyecto integrador - copia\Proyecto integrador - copia"
.venv\Scripts\activate
pip install mediapipe opencv-python flask flask-cors numpy
python mediapipe_server.py
```

### La app dice "MediaPipe server no responde"
1. Verifica que el servidor esté corriendo
2. Abre `http://localhost:5000/health` en el navegador
3. Deberías ver: `{"status": "healthy", "mediapipe": "initialized"}`

### No detecta mi gesto
- ✅ Mejora la iluminación
- ✅ Asegúrate de estar completamente en el frame
- ✅ Haz el gesto lentamente
- ✅ Espera a que se acumulen los 65 frames

---

## 📚 Más Información

- **Guía completa:** `GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md`
- **Resumen técnico:** `RESUMEN_INTEGRACION_COMPLETA.md`
- **Arquitectura:** `CLAUDE.md`

---

**¡Disfruta reconociendo gestos! 🤟**
