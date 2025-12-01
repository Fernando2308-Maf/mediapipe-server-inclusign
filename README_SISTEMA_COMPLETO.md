# 🎯 Sistema Inclusign - Reconocimiento de Gestos en Tiempo Real

## 🌟 ¿Qué es esto?

**Inclusign** es una aplicación móvil/desktop para aprender lenguaje de señas que ahora incluye **reconocimiento de gestos en tiempo real** usando inteligencia artificial.

```
📱 Flutter App  +  🤖 IA (MediaPipe + TensorFlow)  =  🤟 Reconoce 21 gestos
```

---

## 🚀 Inicio Ultra Rápido

### 1. Servidor MediaPipe
```bash
INICIAR_MEDIAPIPE_SERVER.bat  ← Doble clic
```

### 2. App Flutter
```bash
cd inclusing_language_flutter
flutter run -d windows
```

### 3. ¡Usar!
1. Abre la app
2. Ve a "Reconocimiento de Gestos"
3. Presiona "Iniciar"
4. Haz un gesto frente a la cámara
5. Espera ~40 segundos
6. ¡Listo! 🎉

---

## 📚 Documentación Disponible

### 🟢 Para Usuarios
| Archivo | Propósito | ¿Cuándo leer? |
|---------|-----------|---------------|
| **INICIO_RAPIDO.md** | Cómo empezar en 3 pasos | ⭐ Empieza aquí |
| **GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md** | Guía completa de uso | Para usar el sistema |
| **CHECKLIST_VERIFICACION.md** | Lista de comprobación | Si algo no funciona |

### 🟡 Para Desarrolladores
| Archivo | Propósito | ¿Cuándo leer? |
|---------|-----------|---------------|
| **RESUMEN_INTEGRACION_COMPLETA.md** | Qué se cambió y por qué | Para entender la integración |
| **CLAUDE.md** | Arquitectura completa | Para modificar el proyecto |
| **README_MEDIAPIPE.md** | Detalles de MediaPipe | Para trabajar con landmarks |

### 🔧 Herramientas
| Archivo | Propósito |
|---------|-----------|
| **INICIAR_MEDIAPIPE_SERVER.bat** | Inicia el servidor Python |

---

## 🎯 21 Gestos Reconocibles

### Saludos y Cortesía 👋
- hola
- buenos_dias
- buenas_noches
- gracias
- porfavor
- cuidate_mucho

### Conversación 💬
- como_estas
- cual_es_tu_nombre
- mi_nombre_es
- podemos_hablar
- hola_gusto_conocerte

### Comprensión 🧠
- entiendo
- no_entiendo

### Identidad 🆔
- sordo
- oyente
- eres_sordo

### Básicos ✔️❌
- si
- no

### Preguntas ❓
- quien
- porque

### Ayuda 🤝
- puedo_ayudarte

---

## 🏗️ Arquitectura Simplificada

```
┌─────────────────┐
│  📱 Tu Cámara   │
│   (Flutter)     │
└────────┬────────┘
         │ Captura frames
         ↓
┌─────────────────┐
│ 🐍 MediaPipe    │  ← Servidor Python Local
│  (localhost)    │
│  Extrae puntos  │
└────────┬────────┘
         │ 243 números
         ↓
┌─────────────────┐
│ 🤖 Django IA    │  ← En la nube (Render)
│  TensorFlow     │
│  Predice gesto  │
└────────┬────────┘
         │ "hola" (95%)
         ↓
┌─────────────────┐
│  📱 Pantalla    │
│  Muestra gesto  │
└─────────────────┘
```

---

## 📊 Estadísticas

| Métrica | Valor |
|---------|-------|
| **Gestos reconocibles** | 21 |
| **Precisión del modelo** | 94.6% |
| **Tiempo de reconocimiento** | ~40 segundos |
| **Frames necesarios** | 65 |
| **Landmarks detectados** | 81 puntos (243 valores) |

---

## ✅ ¿Qué Necesito?

### Hardware
- ✅ Cámara (laptop, webcam, o móvil)
- ✅ Windows 10+ / Android / iOS
- ✅ 8GB RAM mínimo
- ✅ Internet (solo para predicción final)

### Software
- ✅ Flutter SDK (3.35.7+)
- ✅ Python 3.8+ con venv configurado
- ✅ Servidor MediaPipe corriendo

### Opcional
- 💡 Buena iluminación
- 📏 Espacio para moverte frente a la cámara

---

## 🎓 ¿Cómo Funciona?

### Paso a Paso Técnico

1. **Flutter captura** frame de cámara (30 FPS)
2. **Convierte** YUV420 → JPEG (~70KB)
3. **Envía** a MediaPipe server (localhost:5000)
4. **MediaPipe detecta:**
   - 33 puntos del cuerpo (pose)
   - 6 puntos de la cara
   - 21 puntos mano izquierda
   - 21 puntos mano derecha
   - **Total: 81 puntos**
5. **Retorna** 243 valores (81 × 3 coordenadas)
6. **Flutter envía** landmarks a Django API
7. **Django acumula** 65 frames en buffer
8. **TensorFlow predice** con LSTM bidireccional
9. **Retorna** gesto + confianza + alternativas
10. **Flutter muestra** resultado en pantalla

---

## 🔐 Privacidad

### ✅ Lo que SÍ se hace:
- Captura frames temporales de cámara
- Procesa localmente con MediaPipe
- Envía solo números (landmarks) a internet
- Descarta imágenes inmediatamente

### ❌ Lo que NO se hace:
- No se guardan imágenes
- No se guardan videos
- No se comparte información personal
- Django solo recibe coordenadas numéricas

---

## 🐛 Problemas Comunes

### "Error: MediaPipe server no responde"
**Solución:** Ejecuta `INICIAR_MEDIAPIPE_SERVER.bat`

### "No detecta mi gesto"
**Solución:**
- Mejora la iluminación
- Asegúrate de estar completamente visible
- Haz el gesto lentamente

### "Django API timeout"
**Solución:**
- Es normal la primera vez (30 segundos)
- Ten paciencia

### "Error de compilación Flutter"
**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎨 Capturas de Pantalla

### Vista de Cámara
```
┌──────────────────────────┐
│    📷 Vista de Cámara    │
│                          │
│     ┌──────────────┐     │
│     │    "HOLA"    │     │ ← Overlay del gesto
│     └──────────────┘     │
│                          │
│   [Usuario visible]      │
│                          │
└──────────────────────────┘
```

### Panel de Información
```
┌──────────────────────────┐
│ Estado: ● Detectando     │
│                          │
│ Gesto Reconocido:        │
│ ✨ HOLA                  │
│                          │
│ ✓ Confianza: 95.2%       │
│                          │
│ Otras posibilidades:     │
│ • buenos_dias: 2.1%      │
│ • gracias: 1.5%          │
│                          │
│ Historial:               │
│ [hola] [gracias] [si]    │
└──────────────────────────┘
```

---

## 📞 Soporte

### Documentación
1. Lee `INICIO_RAPIDO.md` primero
2. Si tienes problemas, usa `CHECKLIST_VERIFICACION.md`
3. Para detalles, consulta `GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md`

### Debugging
1. Revisa logs de Flutter (`flutter run`)
2. Revisa logs de MediaPipe server
3. Verifica `http://localhost:5000/health`

---

## 🔮 Roadmap Futuro

### Corto Plazo
- [ ] Reducir frames de 65 a 30 (más rápido)
- [ ] Agregar indicador de progreso visual
- [ ] Feedback háptico al reconocer

### Mediano Plazo
- [ ] Integrar MediaPipe nativamente en Flutter
- [ ] Modo offline completo (sin Django)
- [ ] Más gestos (frases completas)

### Largo Plazo
- [ ] Reconocimiento continuo (múltiples gestos)
- [ ] Traductor en tiempo real
- [ ] Personalización por usuario

---

## 🏆 Créditos

**Desarrollado para:** Inclusign - Educación en Lenguaje de Señas
**Tecnologías:** Flutter, MediaPipe, TensorFlow, Django
**Integración:** Claude Code
**Fecha:** Diciembre 2025

---

## 📄 Licencia

Proyecto educativo - Todos los derechos reservados

---

**¿Listo para empezar? 👉 Lee `INICIO_RAPIDO.md`**

**¿Tienes problemas? 👉 Usa `CHECKLIST_VERIFICACION.md`**

**¿Quieres saber más? 👉 Consulta `GUIA_RECONOCIMIENTO_GESTOS_TIEMPO_REAL.md`**

---

🤟 **¡Feliz reconocimiento de gestos!** 🤟
