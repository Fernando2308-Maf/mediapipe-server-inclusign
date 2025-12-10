"""
MediaPipe Server con Modelo TensorFlow Local

Este servidor combina:
1. Extracción de landmarks con MediaPipe
2. Predicción local con TensorFlow (sin Django API)

Endpoints:
- GET  /health - Estado del servidor y modelo
- POST /extract - Solo extrae landmarks (compatible con versión anterior)
- POST /extract-and-buffer - Extrae landmarks Y acumula en buffer
- POST /predict - Predice gesto desde buffer acumulado
- POST /reset - Limpia el buffer de frames

Uso:
    python mediapipe_server_con_modelo.py
"""

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'  # Reducir warnings de TensorFlow

from flask import Flask, request, jsonify
from flask_cors import CORS
from mediapipe_landmark_extractor import MediaPipeLandmarkExtractor
import cv2
import numpy as np
import base64
import pickle
from collections import deque
import tensorflow as tf

app = Flask(__name__)
CORS(app)  # Habilitar CORS para Flutter

# Inicializar MediaPipe una sola vez
extractor = MediaPipeLandmarkExtractor()

# Buffer de frames (máximo 65)
frame_buffer = deque(maxlen=65)

# Variables globales para el modelo
model = None
label_encoder = None
scaler = None

def load_model():
    """
    Carga el modelo TensorFlow, label encoder y scaler al iniciar el servidor
    """
    global model, label_encoder, scaler

    try:
        # Directorio del proyecto (donde están los archivos .pkl y .keras)
        base_dir = os.path.dirname(os.path.abspath(__file__))

        # Intentar cargar desde C:\Temp primero (para evitar problemas con OneDrive)
        # Si no existe, intentar desde el directorio del proyecto
        temp_dir = r'C:\Temp'
        if os.path.exists(os.path.join(temp_dir, 'modelo_gestos_sin_patron_ceros.keras')):
            model_dir = temp_dir
            print(f"[*] Usando modelos desde C:\\Temp (evitando OneDrive)")
        else:
            model_dir = base_dir
            print(f"[*] Usando modelos desde: {base_dir}")

        # Cargar modelo TensorFlow usando cargador personalizado
        # (evita problemas de permisos con el directorio .keras)
        model_path = os.path.join(model_dir, 'modelo_gestos_sin_patron_ceros.keras')
        print(f"[*] Cargando modelo desde: {model_path}")

        # Importar el cargador personalizado
        import sys
        sys.path.insert(0, base_dir)
        from load_keras3_model import load_keras3_model

        print(f"[*] Usando cargador personalizado para Keras 3.0...")
        model = load_keras3_model(model_path)

        print(f"[+] Modelo cargado correctamente")
        print(f"   Input shape: {model.input_shape}")
        print(f"   Output shape: {model.output_shape}")

        # Cargar label encoder
        label_encoder_path = os.path.join(model_dir, 'label_encoder.pkl')
        print(f"[*] Cargando label encoder desde: {label_encoder_path}")
        with open(label_encoder_path, 'rb') as f:
            label_encoder = pickle.load(f)
        print(f"[+] Label encoder cargado: {len(label_encoder.classes_)} clases")
        print(f"   Clases: {', '.join(label_encoder.classes_[:5])}... (primeras 5)")

        # Cargar scaler (normalizador)
        scaler_path = os.path.join(model_dir, 'normalizacion_sin_patron.pkl')
        print(f"[*] Cargando scaler desde: {scaler_path}")
        with open(scaler_path, 'rb') as f:
            scaler = pickle.load(f)
        print(f"[+] Scaler cargado correctamente")

        print("\n" + "="*60)
        print("[+] Modelo y archivos cargados - Servidor listo para predicciones locales")
        print("="*60 + "\n")

        return True

    except Exception as e:
        print(f"[-] Error cargando modelo: {e}")
        import traceback
        traceback.print_exc()
        return False

def predict_from_buffer():
    """
    Predice el gesto desde el buffer de frames actual

    Returns:
        dict con 'gesto', 'confianza', 'top_3' o None si hay error
    """
    global model, label_encoder, scaler, frame_buffer

    if model is None or label_encoder is None or scaler is None:
        return None

    if len(frame_buffer) < 65:
        return None

    try:
        # Convertir buffer a numpy array (65, 243)
        sequence = np.array(list(frame_buffer))

        # Normalizar con el scaler
        sequence_normalized = scaler.transform(sequence)

        # Reshape para el modelo: (1, 65, 243) - batch de 1 secuencia
        sequence_reshaped = sequence_normalized.reshape(1, 65, 243)

        # Predecir
        predictions = model.predict(sequence_reshaped, verbose=0)
        probabilities = predictions[0]  # Extraer del batch

        # Obtener top 3 predicciones
        top_3_indices = np.argsort(probabilities)[-3:][::-1]

        # Construir resultado
        gesto_principal = label_encoder.classes_[top_3_indices[0]]
        confianza_principal = float(probabilities[top_3_indices[0]])

        top_3 = []
        for idx in top_3_indices:
            top_3.append({
                'gesto': label_encoder.classes_[idx],
                'prob': float(probabilities[idx])
            })

        return {
            'gesto': gesto_principal,
            'confianza': confianza_principal,
            'top_3': top_3
        }

    except Exception as e:
        print(f"[-] Error en prediccion: {e}")
        import traceback
        traceback.print_exc()
        return None

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
    """Verifica que MediaPipe y el modelo estén funcionando"""
    model_status = "loaded" if model is not None else "not_loaded"
    encoder_status = "loaded" if label_encoder is not None else "not_loaded"
    scaler_status = "loaded" if scaler is not None else "not_loaded"

    num_classes = len(label_encoder.classes_) if label_encoder is not None else 0
    buffer_size = len(frame_buffer)

    return jsonify({
        'status': 'healthy',
        'mediapipe': 'initialized',
        'model': model_status,
        'label_encoder': encoder_status,
        'scaler': scaler_status,
        'num_classes': num_classes,
        'buffer_frames': buffer_size,
        'max_buffer': 65
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
        landmarks, results, annotated_frame = extractor.process_frame(frame)

        # Convertir a lista plana (243 valores)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        # Información de detecciones
        detections = {
            'pose': results.pose_landmarks is not None,
            'face': results.face_landmarks is not None,
            'left_hand': results.left_hand_landmarks is not None,
            'right_hand': results.right_hand_landmarks is not None
        }

        # Convertir frame anotado a base64 para enviarlo a Flutter
        _, buffer = cv2.imencode('.jpg', annotated_frame)
        annotated_image_base64 = base64.b64encode(buffer).decode('utf-8')

        return jsonify({
            'landmarks': flat_landmarks,
            'success': True,
            'detections': detections,
            'landmarks_count': len(flat_landmarks),
            'annotated_image': annotated_image_base64  # Imagen con landmarks dibujados
        })

    except Exception as e:
        print(f'❌ Error procesando imagen: {e}')
        return jsonify({
            'error': str(e),
            'success': False
        }), 500


@app.route('/extract-and-buffer', methods=['POST'])
def extract_and_buffer():
    """
    Extrae landmarks Y los acumula en el buffer
    Cuando llega a 65 frames, predice automáticamente con el modelo local

    Request JSON:
    {
        "image": "base64_encoded_image_data"
    }

    Response (< 65 frames):
    {
        "success": true,
        "estado": "acumulando",
        "frames": N,
        "frames_restantes": 65-N
    }

    Response (== 65 frames):
    {
        "success": true,
        "estado": "prediccion",
        "gesto": "HOLA",
        "confianza": 0.95,
        "top_3": [{"gesto": "HOLA", "prob": 0.95}, ...]
    }
    """
    try:
        # Validar request
        if not request.json or 'image' not in request.json:
            return jsonify({
                'error': 'No se envió imagen en el request',
                'success': False
            }), 400

        # Extraer landmarks
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

        # Verificar que se detectaron landmarks
        if not results.pose_landmarks:
            return jsonify({
                'success': False,
                'error': 'No se detectaron landmarks',
                'detections': {
                    'pose': False,
                    'face': results.face_landmarks is not None,
                    'left_hand': results.left_hand_landmarks is not None,
                    'right_hand': results.right_hand_landmarks is not None
                }
            }), 200

        # Agregar landmarks al buffer
        frame_buffer.append(flat_landmarks)

        current_frames = len(frame_buffer)
        print(f"📊 Buffer: {current_frames}/65 frames")

        # Si tenemos 65 frames, predecir
        if current_frames >= 65:
            prediction = predict_from_buffer()

            if prediction is None:
                return jsonify({
                    'success': False,
                    'error': 'Error en predicción del modelo'
                }), 500

            # Limpiar buffer después de predicción
            frame_buffer.clear()

            print(f"✅ PREDICCIÓN: {prediction['gesto']} ({prediction['confianza']:.2%})")

            return jsonify({
                'success': True,
                'estado': 'prediccion',
                'gesto': prediction['gesto'],
                'confianza': prediction['confianza'],
                'top_3': prediction['top_3']
            })
        else:
            # Todavía acumulando frames
            return jsonify({
                'success': True,
                'estado': 'acumulando',
                'frames': current_frames,
                'frames_restantes': 65 - current_frames
            })

    except Exception as e:
        print(f'❌ Error: {e}')
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

@app.route('/reset', methods=['POST'])
def reset_buffer():
    """
    Limpia el buffer de frames
    Útil para empezar una nueva captura
    """
    frame_buffer.clear()
    return jsonify({
        'success': True,
        'message': 'Buffer limpiado',
        'frames': 0
    })


if __name__ == '__main__':
    import sys
    import io

    # Configurar salida UTF-8 para Windows
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    except:
        pass

    print('\n' + '=' * 60)
    print('MediaPipe Server con Modelo TensorFlow Local')
    print('=' * 60)

    # Cargar modelo al iniciar
    if not load_model():
        print("\n❌ ADVERTENCIA: El modelo no se cargó correctamente")
        print("El servidor funcionará pero sin capacidad de predicción local\n")

    # Obtener puerto de variable de entorno (para Render/Heroku)
    port = int(os.environ.get('PORT', 5000))

    print('\n🚀 Iniciando servidor Flask en http://0.0.0.0:' + str(port))
    print('\nEndpoints disponibles:')
    print('  GET  / ..................... Health check')
    print('  GET  /health ............... Verifica MediaPipe y modelo')
    print('  POST /extract .............. Extrae landmarks solamente')
    print('  POST /extract-and-buffer ... Extrae landmarks y acumula para predicción LOCAL')
    print('  POST /reset ................ Limpia el buffer de frames')
    print()
    print('Presiona Ctrl+C para detener')
    print('=' * 60 + '\n')

    # Ejecutar servidor
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False  # False en producción
    )
