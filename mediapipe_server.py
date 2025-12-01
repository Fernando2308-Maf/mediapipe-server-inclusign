"""
MediaPipe Server - Servidor HTTP para extraer landmarks

Este servidor Flask recibe frames de Flutter y retorna landmarks
usando MediaPipe Python.

Uso:
    python mediapipe_server.py

El servidor se ejecuta en http://localhost:5000
Endpoint: POST /extract
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from mediapipe_landmark_extractor import MediaPipeLandmarkExtractor
import cv2
import numpy as np
import base64

app = Flask(__name__)
CORS(app)  # Habilitar CORS para Flutter

# Inicializar MediaPipe una sola vez
extractor = MediaPipeLandmarkExtractor()

@app.route('/', methods=['GET'])
def home():
    """Health check endpoint"""
    return jsonify({
        'status': 'running',
        'version': '1.0.0',
        'endpoints': {
            '/extract': 'POST - Extrae landmarks de una imagen',
            '/health': 'GET - Verifica el estado del servidor'
        }
    })

@app.route('/health', methods=['GET'])
def health():
    """Verifica que MediaPipe esté funcionando"""
    return jsonify({
        'status': 'healthy',
        'mediapipe': 'initialized'
    })

@app.route('/extract', methods=['POST'])
def extract_landmarks():
    """
    Extrae landmarks de una imagen

    Request JSON:
    {
        "image": "base64_encoded_image_data"
    }

    Response JSON (Success):
    {
        "landmarks": [...243 valores...],
        "success": true,
        "detections": {
            "pose": true/false,
            "face": true/false,
            "left_hand": true/false,
            "right_hand": true/false
        }
    }

    Response JSON (Error):
    {
        "error": "mensaje de error",
        "success": false
    }
    """
    try:
        # Validar que se envió data
        if not request.json or 'image' not in request.json:
            return jsonify({
                'error': 'No se envió imagen en el request',
                'success': False
            }), 400

        # Recibir imagen en base64
        image_data = request.json['image']

        # Si viene con prefijo data:image, quitarlo
        if ',' in image_data:
            image_data = image_data.split(',')[1]

        # Decodificar base64
        image_bytes = base64.b64decode(image_data)

        # Convertir a numpy array
        nparr = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({
                'error': 'No se pudo decodificar la imagen',
                'success': False
            }), 400

        # Procesar con MediaPipe
        landmarks, results, _ = extractor.process_frame(frame)

        # Convertir a lista plana (243 valores)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        # Información de detecciones
        detections = {
            'pose': results.pose_landmarks is not None,
            'face': results.face_landmarks is not None,
            'left_hand': results.left_hand_landmarks is not None,
            'right_hand': results.right_hand_landmarks is not None
        }

        return jsonify({
            'landmarks': flat_landmarks,
            'success': True,
            'detections': detections,
            'landmarks_count': len(flat_landmarks)
        })

    except Exception as e:
        print(f'❌ Error procesando imagen: {e}')
        return jsonify({
            'error': str(e),
            'success': False
        }), 500


@app.route('/extract-and-predict', methods=['POST'])
def extract_and_predict():
    """
    Extrae landmarks de una imagen y opcionalmente los envía a la API de Django

    Request JSON:
    {
        "image": "base64_encoded_image_data",
        "send_to_api": true/false (opcional, default: false)
    }
    """
    try:
        # Validar request
        if not request.json or 'image' not in request.json:
            return jsonify({
                'error': 'No se envió imagen en el request',
                'success': False
            }), 400

        # Extraer landmarks (mismo código que /extract)
        image_data = request.json['image']
        if ',' in image_data:
            image_data = image_data.split(',')[1]

        image_bytes = base64.b64decode(image_data)
        nparr = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({
                'error': 'No se pudo decodificar la imagen',
                'success': False
            }), 400

        landmarks, results, _ = extractor.process_frame(frame)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        response_data = {
            'landmarks': flat_landmarks,
            'success': True,
            'detections': {
                'pose': results.pose_landmarks is not None,
                'face': results.face_landmarks is not None,
                'left_hand': results.left_hand_landmarks is not None,
                'right_hand': results.right_hand_landmarks is not None
            }
        }

        # Si se solicita, enviar a la API de Django
        if request.json.get('send_to_api', False):
            import requests

            django_url = 'https://django-rest-framework-uc05.onrender.com/api/predict/'

            try:
                django_response = requests.post(
                    django_url,
                    json={'landmarks': flat_landmarks},
                    timeout=30
                )

                if django_response.status_code == 200:
                    response_data['prediction'] = django_response.json()
                else:
                    response_data['prediction_error'] = f'API retornó {django_response.status_code}'

            except Exception as e:
                response_data['prediction_error'] = str(e)

        return jsonify(response_data)

    except Exception as e:
        print(f'❌ Error: {e}')
        return jsonify({
            'error': str(e),
            'success': False
        }), 500


if __name__ == '__main__':
    print('=' * 60)
    print('🚀 MediaPipe Server - Inclusign')
    print('=' * 60)
    print()
    print('Endpoints disponibles:')
    print('  GET  / .................. Health check')
    print('  GET  /health ............ Verifica MediaPipe')
    print('  POST /extract ........... Extrae landmarks')
    print('  POST /extract-and-predict  Extrae y predice')
    print()
    print('Servidor corriendo en: http://localhost:5000')
    print('Presiona Ctrl+C para detener')
    print('=' * 60)
    print()

    # Ejecutar servidor
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )
