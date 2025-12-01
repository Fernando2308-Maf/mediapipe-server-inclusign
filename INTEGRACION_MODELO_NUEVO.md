# Integración del Nuevo Modelo de Reconocimiento de Gestos

**Fecha**: 1 de diciembre de 2025
**Modelo**: `modelo_gestos_sin_patron_ceros.keras`
**Precisión**: 94.6%

---

## Resumen Ejecutivo

Se ha integrado exitosamente un nuevo modelo de TensorFlow para reconocimiento de gestos de lenguaje de señas. El modelo reconoce **21 gestos diferentes** con una precisión del 94.6%.

---

## Cambios Realizados

### 1. Backend Django (django-rest-framework)

**Archivos modificados:**
- `api/services/predictor.py` - Actualizado para usar el nuevo modelo
- `api/ml/label_encoder.pkl` - Agregado (codificador de etiquetas)

**Commit creado:**
```
commit a943ccc
Author: Fernando
Date:   Sun Dec 1 16:38:00 2025

    Actualizar modelo de reconocimiento de gestos

    - Usar modelo_gestos_sin_patron_ceros.keras con 21 gestos
    - Actualizar label_encoder.pkl con clases correctas
    - Precisión del modelo: 94.6%
    - Gestos: hola, buenos_dias, gracias, si, no, etc.
```

**Estado del despliegue:**
- ⚠️ Cambios commiteados localmente pero **NO desplegados a Render**
- Razón: Permisos insuficientes para hacer push al repositorio de RamonCarrillo90
- Acción requerida: El dueño del repositorio debe hacer `git pull` y `git push` desde su máquina

### 2. Flutter App

**Estado:**
- ✅ Ya estaba correctamente configurado para enviar 81 landmarks × 3 coordenadas
- ✅ Acumula 65 frames antes de enviar a la API
- ✅ APK reconstruido con las correcciones previas del sistema de reconocimiento

**APK generado:**
- Ubicación: `inclusing_language_flutter/build/app/outputs/flutter-apk/app-release.apk`
- Tamaño: 232.5 MB
- Fecha: 1 de diciembre de 2025, 16:42

---

## Especificaciones Técnicas del Modelo

### Formato de Entrada

```python
Shape: (batch_size, 65, 243)
```

Donde:
- **65 frames**: Secuencia temporal de gestos
- **243 features**: 81 landmarks × 3 coordenadas (x, y, z)

### Desglose de Landmarks (81 puntos totales)

| Categoría | Cantidad | Índices |
|-----------|----------|---------|
| Pose (cuerpo) | 33 | 0-32 |
| Cara (puntos clave) | 6 | 33-38 |
| Mano izquierda | 21 | 39-59 |
| Mano derecha | 21 | 60-80 |

**Nota**: Los landmarks de las manos están parcialmente implementados en ML Kit (solo muñeca, el resto en ceros).

### Arquitectura del Modelo

- **Tipo**: Bidirectional LSTM
- **Preprocessing**: `zeros_replaced_with_unique_noise`
- **Normalización**: Z-score (media y desviación estándar global)

### Gestos Reconocidos (21 clases)

1. buenas_noches
2. buenos_dias
3. como_estas
4. cual_es_tu_nombre
5. cuidate_mucho
6. entiendo
7. eres_sordo
8. gracias
9. hola
10. hola_gusto_conocerte
11. mi_nombre_es
12. no
13. no_entiendo
14. oyente
15. podemos_hablar
16. porfavor
17. porque
18. puedo_ayudarte
19. quien
20. si
21. sordo

---

## Flujo de Datos Completo

```
[Flutter App - Camera]
        ↓
   CameraImage (YUV420)
        ↓
[ML Kit - Pose + Face Detection]
        ↓
   81 landmarks × 3 coords = 243 valores
        ↓
[Acumulación de 65 frames]
        ↓
POST https://django-rest-framework-uc05.onrender.com/api/predict/
   Body: {"landmarks": [243 valores]}
        ↓
[Django API - Sequence Buffer]
   - Acumula frames hasta tener 65
        ↓
[Predictor Service]
   - Normaliza: (X - mean) / std
   - Reshape: (1, 65, 243)
        ↓
[TensorFlow Model]
   - Bidirectional LSTM
   - Predicción: probabilidades de 21 clases
        ↓
[LabelEncoder]
   - Convierte índice → nombre del gesto
        ↓
Response: {
  "gesto": "hola",
  "confianza": 0.95,
  "top_3": [
    {"gesto": "hola", "prob": 0.95},
    {"gesto": "buenos_dias", "prob": 0.03},
    {"gesto": "gracias", "prob": 0.01}
  ]
}
        ↓
[Flutter UI]
   - Muestra gesto reconocido
   - Overlay con confianza
   - Historial de gestos
```

---

## Archivos del Modelo en Django

**Ubicación**: `django-rest-framework/api/ml/`

| Archivo | Descripción | Tamaño |
|---------|-------------|--------|
| `modelo_gestos_sin_patron_ceros.keras` | Modelo TensorFlow | ~6.9 MB |
| `label_encoder.pkl` | Codificador de etiquetas (21 clases) | ~1.9 KB |
| `normalizacion_sin_patron.pkl` | Media y std para normalización | ~172 B |
| `metadata_sin_patron.pkl` | Metadatos del modelo | ~508 B |

---

## Estado del Sistema

### ✅ Completado

1. ✅ Inspección del label_encoder.pkl
2. ✅ Verificación del formato de entrada (65 frames × 81 landmarks × 3 coords)
3. ✅ Copia del label_encoder.pkl a Django
4. ✅ Actualización de `predictor.py` para usar archivos correctos
5. ✅ Construcción del APK con correcciones
6. ✅ Commit de cambios en Django

### ⚠️ Pendiente

1. ⚠️ **Despliegue a Render**: Requiere permisos de push al repositorio
2. ⚠️ **Prueba en producción**: Una vez desplegado a Render

---

## Instrucciones para Despliegue a Render

**Para el dueño del repositorio (RamonCarrillo90):**

```bash
cd django-rest-framework

# Ver cambios pendientes
git log -1

# Hacer push a GitHub (Render hace auto-deploy)
git push origin main
```

**O bien, si no tienes acceso:**

1. Crear un pull request desde este fork
2. Fusionar en el repositorio principal
3. Render detectará el cambio y desplegará automáticamente

---

## Pruebas Recomendadas

### Después de Desplegar a Render:

1. **Probar endpoint directamente**:
   ```bash
   curl -X POST https://django-rest-framework-uc05.onrender.com/api/predict/ \
     -H "Content-Type: application/json" \
     -d '{"landmarks": [... 243 valores ...]}'
   ```

2. **Instalar APK en el celular**:
   - Ubicación: `inclusing_language_flutter/build/app/outputs/flutter-apk/app-release.apk`
   - Transferir al celular e instalar
   - Abrir la app → Módulo de cámara
   - Presionar "Iniciar"
   - Realizar gestos frente a la cámara

3. **Verificar logs**:
   - Flutter: Buscar mensajes "📤 Enviando frame X a la API..."
   - Django: Logs en Render dashboard

---

## Troubleshooting

### Problema: API timeout o error 500

**Causa posible**: Render hace "cold start" y tarda ~30 segundos en cargar el modelo

**Solución**: Esperar y reintentar. El primer request siempre es lento.

---

### Problema: Gesto no reconocido o siempre muestra el mismo

**Causa posible**: ML Kit no detecta pose o cara correctamente

**Síntomas**:
- Flutter muestra "Usando modo de prueba (ML Kit no disponible)"
- O simplemente no avanza el contador de frames

**Solución**:
1. Verificar iluminación
2. Asegurarse de que todo el cuerpo está en el cuadro
3. Mantener las manos visibles

---

### Problema: No se despliega a Render

**Causa**: Permisos insuficientes en GitHub

**Solución**: Contactar al dueño del repositorio (RamonCarrillo90) para que haga el push

---

## Archivos de Referencia

- **Código actual de Flutter**: `inclusing_language_flutter/lib/screens/gesture_camera_screen.dart`
- **Servicio de reconocimiento**: `inclusing_language_flutter/lib/services/gesture_recognition_service.dart`
- **Predictor Django**: `django-rest-framework/api/services/predictor.py`
- **Buffer de secuencias**: `django-rest-framework/api/services/sequence_buffer.py`

---

## Notas Adicionales

### Diferencias con el Modelo Anterior

El modelo anterior (si existía) podría haber tenido:
- Menos clases de gestos
- Diferente formato de landmarks
- Archivos con diferentes nombres (`modelo_gestos.keras` vs `modelo_gestos_sin_patron_ceros.keras`)

El nuevo modelo usa el sufijo `_sin_patron_ceros` porque reemplaza los ceros de los landmarks faltantes con ruido único, lo que mejora la precisión.

### Próximas Mejoras Sugeridas

1. **Implementar MediaPipe Holistic completo**: Para obtener los 21 landmarks completos de cada mano
2. **Reducir latencia**: Optimizar el modelo con TensorFlow Lite para ejecución local en el dispositivo
3. **Agregar más gestos**: Entrenar el modelo con más clases del diccionario de señas
4. **Modo offline**: Incluir el modelo `.tflite` en el APK para funcionar sin conexión

---

**Última actualización**: 1 de diciembre de 2025, 16:45
**Responsable**: Claude Code con supervisión de Fernando
