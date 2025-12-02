# MediaPipe Server - Inclusign

Servidor Flask para extraer landmarks de MediaPipe para reconocimiento de gestos en lengua de señas.

## Descripción

Este servidor recibe imágenes desde la aplicación móvil Inclusign y extrae landmarks usando MediaPipe Python.

## Endpoints

- `GET /` - Health check
- `GET /health` - Verifica que MediaPipe esté funcionando
- `POST /extract` - Extrae landmarks de una imagen

## Deploy en Render

Este servidor está configurado para desplegarse automáticamente en Render.

## Uso Local

```bash
pip install -r requirements.txt
python mediapipe_server.py
```

El servidor se ejecuta en `http://localhost:5000`

## Tecnologías

- Flask
- MediaPipe
- OpenCV
- NumPy
