"""
Test Completo del Pipeline de Reconocimiento de Gestos

Este script prueba el flujo completo:
1. MediaPipe extrae landmarks de webcam
2. Se envían a la API Django
3. Se muestra la predicción en tiempo real

Uso:
    python test_complete_pipeline.py
"""

import cv2
import requests
import numpy as np
from mediapipe_landmark_extractor import MediaPipeLandmarkExtractor
import time

# Configuración
DJANGO_API_URL = 'https://django-rest-framework-uc05.onrender.com/api/predict/'
FRAME_DELAY_MS = 100  # Capturar cada 100ms (10 FPS)

def test_pipeline():
    """
    Prueba el pipeline completo de reconocimiento de gestos
    """
    print("=" * 70)
    print("🧪 TEST COMPLETO - Pipeline de Reconocimiento de Gestos")
    print("=" * 70)
    print()

    # Inicializar MediaPipe
    print("📦 Inicializando MediaPipe...")
    extractor = MediaPipeLandmarkExtractor()

    # Abrir webcam
    print("🎥 Abriendo webcam...")
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("❌ Error: No se pudo abrir la cámara")
        return

    print("✅ Cámara inicializada")
    print()
    print("Instrucciones:")
    print("  - Colócate frente a la cámara con todo tu cuerpo visible")
    print("  - Realiza gestos de lenguaje de señas")
    print("  - El sistema capturará 65 frames antes de predecir")
    print("  - Presiona 'q' para salir")
    print()
    print("=" * 70)
    print()

    frame_count = 0
    last_prediction = None
    prediction_history = []

    while True:
        success, frame = cap.read()
        if not success:
            print("❌ Error leyendo frame")
            break

        # Procesar con MediaPipe
        landmarks, results, annotated_frame = extractor.process_frame(frame)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        # Contador de frames
        frame_count += 1

        # Verificar detecciones
        detections_status = []
        if results.pose_landmarks:
            detections_status.append("Pose ✓")
        if results.face_landmarks:
            detections_status.append("Cara ✓")
        if results.left_hand_landmarks:
            detections_status.append("Mano Izq ✓")
        if results.right_hand_landmarks:
            detections_status.append("Mano Der ✓")

        # Mostrar información en frame
        y_pos = 30
        cv2.putText(annotated_frame, f'Frame: {frame_count}', (10, y_pos),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        y_pos += 30

        detection_text = f"Detectado: {', '.join(detections_status) if detections_status else 'Nada'}"
        cv2.putText(annotated_frame, detection_text, (10, y_pos),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)
        y_pos += 30

        # Enviar a API cada N frames
        if frame_count % 10 == 0:  # Cada 10 frames (1 segundo a 10 FPS)
            try:
                print(f"📤 Enviando frame {frame_count} a la API...")

                response = requests.post(
                    DJANGO_API_URL,
                    json={'landmarks': flat_landmarks},
                    timeout=5
                )

                if response.status_code == 200:
                    data = response.json()

                    if 'estado' in data:
                        # Aún esperando frames
                        print(f"   ⏳ {data['estado']}")
                        cv2.putText(annotated_frame, data['estado'], (10, y_pos),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (100, 100, 255), 2)
                    elif 'gesto' in data:
                        # Predicción recibida!
                        last_prediction = data
                        prediction_history.append(data['gesto'])

                        print(f"   ✅ PREDICCIÓN: {data['gesto']}")
                        print(f"   📊 Confianza: {data['confianza']*100:.1f}%")

                        if 'top_3' in data:
                            print(f"   🏆 Top 3:")
                            for item in data['top_3']:
                                print(f"      - {item['gesto']}: {item['prob']*100:.1f}%")

                        # Mostrar en pantalla
                        cv2.putText(annotated_frame, f"GESTO: {data['gesto']}", (10, y_pos),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 3)
                        y_pos += 40
                        cv2.putText(annotated_frame, f"Confianza: {data['confianza']*100:.1f}%", (10, y_pos),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

                        print()
                else:
                    print(f"   ❌ Error API: {response.status_code}")

            except requests.Timeout:
                print(f"   ⏱️ Timeout - La API tardó demasiado")
            except Exception as e:
                print(f"   ❌ Error: {e}")

        # Mostrar última predicción si existe
        if last_prediction:
            y_bottom = annotated_frame.shape[0] - 20
            cv2.putText(annotated_frame, f"Último: {last_prediction['gesto']}", (10, y_bottom),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        # Mostrar frame
        cv2.imshow('Test Pipeline - Inclusign', annotated_frame)

        # Esperar y verificar tecla
        if cv2.waitKey(FRAME_DELAY_MS) & 0xFF == ord('q'):
            break

    # Cleanup
    cap.release()
    cv2.destroyAllWindows()
    extractor.close()

    # Mostrar resumen
    print()
    print("=" * 70)
    print("📊 RESUMEN DE LA SESIÓN")
    print("=" * 70)
    print(f"Total de frames procesados: {frame_count}")
    print(f"Gestos detectados: {len(prediction_history)}")

    if prediction_history:
        print(f"\nGestos reconocidos:")
        from collections import Counter
        gesture_counts = Counter(prediction_history)
        for gesture, count in gesture_counts.most_common():
            print(f"  - {gesture}: {count} veces")

    print()
    print("✅ Test completado")


def test_single_frame():
    """
    Prueba con un solo frame para verificar conectividad
    """
    print("🧪 Test Rápido - Un Solo Frame")
    print()

    extractor = MediaPipeLandmarkExtractor()
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("❌ Error: No se pudo abrir la cámara")
        return

    # Capturar un frame
    success, frame = cap.read()
    if not success:
        print("❌ Error capturando frame")
        return

    # Procesar
    landmarks, results, _ = extractor.process_frame(frame)
    flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

    print(f"✅ Landmarks extraídos: {len(flat_landmarks)} valores")
    print(f"   Pose: {'✓' if results.pose_landmarks else '✗'}")
    print(f"   Cara: {'✓' if results.face_landmarks else '✗'}")
    print(f"   Mano Izq: {'✓' if results.left_hand_landmarks else '✗'}")
    print(f"   Mano Der: {'✓' if results.right_hand_landmarks else '✗'}")
    print()

    # Probar API
    print("📤 Enviando a la API Django...")
    try:
        response = requests.post(
            DJANGO_API_URL,
            json={'landmarks': flat_landmarks},
            timeout=10
        )

        if response.status_code == 200:
            data = response.json()
            print(f"✅ Respuesta recibida:")
            print(f"   {data}")
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"   {response.text}")

    except Exception as e:
        print(f"❌ Error: {e}")

    cap.release()
    extractor.close()


if __name__ == "__main__":
    import sys

    print()
    if len(sys.argv) > 1 and sys.argv[1] == 'quick':
        test_single_frame()
    else:
        test_pipeline()
