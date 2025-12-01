"""
MediaPipe Landmark Extractor - Helper para integrar con Flutter

Este script muestra cómo extraer los 81 landmarks (243 valores) en el formato exacto
que espera tu modelo de TensorFlow en Django.

Formato esperado:
- 33 puntos de pose (cuerpo) × 3 coordenadas = 99 valores
- 6 puntos de cara × 3 coordenadas = 18 valores
- 21 puntos de mano izquierda × 3 coordenadas = 63 valores
- 21 puntos de mano derecha × 3 coordenadas = 63 valores
TOTAL: 243 valores (81 puntos × 3)

Puedes usar este código como referencia para implementar en Flutter
o crear un servicio HTTP intermedio.
"""

import cv2
import mediapipe as mp
import numpy as np

class MediaPipeLandmarkExtractor:
    def __init__(self):
        # Inicializar soluciones de MediaPipe
        self.mp_holistic = mp.solutions.holistic
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles

        # Configurar Holistic (detecta pose, manos y cara en una sola pasada)
        self.holistic = self.mp_holistic.Holistic(
            static_image_mode=False,
            model_complexity=1,  # 0=Lite, 1=Full, 2=Heavy
            smooth_landmarks=True,
            enable_segmentation=False,
            smooth_segmentation=False,
            refine_face_landmarks=True,  # Más landmarks de cara
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )

    def extract_keypoints(self, results):
        """
        Convierte landmarks en arrays con forma (81, 3) manteniendo coordenadas XYZ.

        Returns:
            np.array: Array de forma (81, 3) o lista plana de 243 valores
        """
        # 1. Pose: 33 puntos × 3 coordenadas = (33, 3)
        if results.pose_landmarks:
            pose = np.array([[lm.x, lm.y, lm.z] for lm in results.pose_landmarks.landmark])
        else:
            pose = np.zeros((33, 3))

        # 2. Cara: 6 puntos específicos × 3 coordenadas = (6, 3)
        # Índices de MediaPipe Face Mesh: [1, 33, 263, 61, 291, 199]
        if results.face_landmarks:
            face_indices = [1, 33, 263, 61, 291, 199]
            face = np.array([[
                results.face_landmarks.landmark[i].x,
                results.face_landmarks.landmark[i].y,
                results.face_landmarks.landmark[i].z
            ] for i in face_indices])
        else:
            face = np.zeros((6, 3))

        # 3. Mano izquierda: 21 puntos × 3 coordenadas = (21, 3)
        if results.left_hand_landmarks:
            lh = np.array([[lm.x, lm.y, lm.z] for lm in results.left_hand_landmarks.landmark])
        else:
            lh = np.zeros((21, 3))

        # 4. Mano derecha: 21 puntos × 3 coordenadas = (21, 3)
        if results.right_hand_landmarks:
            rh = np.array([[lm.x, lm.y, lm.z] for lm in results.right_hand_landmarks.landmark])
        else:
            rh = np.zeros((21, 3))

        # Concatenar todo manteniendo la forma (81, 3)
        # Orden: pose (33) + cara (6) + mano_izq (21) + mano_der (21) = 81
        landmarks = np.vstack([pose, face, lh, rh])

        return landmarks  # Forma (81, 3)

    def process_frame(self, frame):
        """
        Procesa un frame de video y extrae los landmarks.

        Args:
            frame: Frame de OpenCV (BGR)

        Returns:
            tuple: (landmarks_array, results, frame_con_dibujo)
        """
        # Convertir BGR a RGB (MediaPipe usa RGB)
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image_rgb.flags.writeable = False

        # Procesar con MediaPipe Holistic
        results = self.holistic.process(image_rgb)

        # Convertir de vuelta a BGR para dibujar
        image_rgb.flags.writeable = True
        image_bgr = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2BGR)

        # Dibujar landmarks en el frame
        if results.pose_landmarks:
            self.mp_drawing.draw_landmarks(
                image_bgr,
                results.pose_landmarks,
                self.mp_holistic.POSE_CONNECTIONS,
                landmark_drawing_spec=self.mp_drawing_styles.get_default_pose_landmarks_style()
            )

        if results.face_landmarks:
            self.mp_drawing.draw_landmarks(
                image_bgr,
                results.face_landmarks,
                self.mp_holistic.FACEMESH_CONTOURS,
                landmark_drawing_spec=None,
                connection_drawing_spec=self.mp_drawing_styles.get_default_face_mesh_contours_style()
            )

        if results.left_hand_landmarks:
            self.mp_drawing.draw_landmarks(
                image_bgr,
                results.left_hand_landmarks,
                self.mp_holistic.HAND_CONNECTIONS,
                self.mp_drawing_styles.get_default_hand_landmarks_style(),
                self.mp_drawing_styles.get_default_hand_connections_style()
            )

        if results.right_hand_landmarks:
            self.mp_drawing.draw_landmarks(
                image_bgr,
                results.right_hand_landmarks,
                self.mp_holistic.HAND_CONNECTIONS,
                self.mp_drawing_styles.get_default_hand_landmarks_style(),
                self.mp_drawing_styles.get_default_hand_connections_style()
            )

        # Extraer landmarks
        landmarks = self.extract_keypoints(results)

        return landmarks, results, image_bgr

    def landmarks_to_flat_list(self, landmarks):
        """
        Convierte array (81, 3) a lista plana de 243 valores.
        Útil para enviar a la API Django.
        """
        return landmarks.flatten().tolist()

    def close(self):
        """Liberar recursos"""
        self.holistic.close()


def demo_webcam():
    """
    Demo en tiempo real usando la webcam.
    Presiona 'q' para salir.
    """
    extractor = MediaPipeLandmarkExtractor()
    cap = cv2.VideoCapture(0)

    print("🎥 Demo MediaPipe - Presiona 'q' para salir")
    print("📊 Formato de salida: 81 puntos × 3 coordenadas = 243 valores")

    frame_count = 0

    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            print("❌ No se puede leer de la cámara")
            break

        # Procesar frame
        landmarks, results, annotated_frame = extractor.process_frame(frame)

        # Convertir a lista plana (formato API)
        flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

        # Mostrar información en pantalla
        frame_count += 1
        cv2.putText(annotated_frame, f'Frame: {frame_count}', (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.putText(annotated_frame, f'Landmarks: {len(flat_landmarks)}', (10, 70),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        # Verificar detecciones
        detections = []
        if results.pose_landmarks:
            detections.append("Pose")
        if results.face_landmarks:
            detections.append("Cara")
        if results.left_hand_landmarks:
            detections.append("Mano Izq")
        if results.right_hand_landmarks:
            detections.append("Mano Der")

        detection_text = f"Detectado: {', '.join(detections) if detections else 'Nada'}"
        cv2.putText(annotated_frame, detection_text, (10, 110),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2)

        # Mostrar frame
        cv2.imshow('MediaPipe Holistic - Demo', annotated_frame)

        # Imprimir ejemplo de datos cada 30 frames
        if frame_count % 30 == 0:
            print(f"\n📊 Frame {frame_count}:")
            print(f"   Landmarks shape: {landmarks.shape}")
            print(f"   Flat list length: {len(flat_landmarks)}")
            print(f"   Primeros 9 valores: {flat_landmarks[:9]}")
            print(f"   Detecciones: {detection_text}")

        # Salir con 'q'
        if cv2.waitKey(5) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    extractor.close()
    print("\n✅ Demo finalizada")


def demo_single_image(image_path):
    """
    Procesa una sola imagen y muestra los landmarks.

    Args:
        image_path: Ruta a la imagen
    """
    extractor = MediaPipeLandmarkExtractor()

    # Cargar imagen
    frame = cv2.imread(image_path)
    if frame is None:
        print(f"❌ No se pudo cargar la imagen: {image_path}")
        return

    # Procesar
    landmarks, results, annotated_frame = extractor.process_frame(frame)
    flat_landmarks = extractor.landmarks_to_flat_list(landmarks)

    # Mostrar resultados
    print(f"✅ Imagen procesada: {image_path}")
    print(f"📊 Landmarks shape: {landmarks.shape}")
    print(f"📊 Flat list length: {len(flat_landmarks)}")
    print(f"📊 Primeros 9 valores: {flat_landmarks[:9]}")

    # Mostrar imagen
    cv2.imshow('MediaPipe Holistic - Imagen', annotated_frame)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    extractor.close()

    return landmarks, flat_landmarks


if __name__ == "__main__":
    import sys

    print("=" * 60)
    print("MediaPipe Landmark Extractor - Inclusign")
    print("=" * 60)
    print()
    print("Modos de uso:")
    print("  python mediapipe_landmark_extractor.py           - Demo con webcam")
    print("  python mediapipe_landmark_extractor.py <imagen>  - Procesar imagen")
    print()

    if len(sys.argv) > 1:
        # Modo imagen
        demo_single_image(sys.argv[1])
    else:
        # Modo webcam
        demo_webcam()
