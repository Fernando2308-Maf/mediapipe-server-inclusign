"""
Script para guardar landmarks recibidos del móvil y compararlos con escritorio

Este script modifica temporalmente el servidor MediaPipe para guardar:
1. La imagen recibida del móvil (JPEG)
2. Los landmarks extraídos
3. Diagnóstico de detecciones

Luego podemos compararlos con los landmarks del escritorio.
"""

import os
import json
from datetime import datetime

# Directorio para guardar datos de debug
DEBUG_DIR = "debug_landmarks"
os.makedirs(DEBUG_DIR, exist_ok=True)

def save_debug_data(image_bytes, landmarks, detections, source="movil"):
    """
    Guarda datos de debug para análisis posterior

    Args:
        image_bytes: Bytes de la imagen JPEG
        landmarks: Lista de 243 valores
        detections: Dict con detecciones
        source: 'movil' o 'escritorio'
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    filename_prefix = f"{DEBUG_DIR}/{source}_{timestamp}"

    # Guardar imagen
    image_path = f"{filename_prefix}.jpg"
    with open(image_path, 'wb') as f:
        f.write(image_bytes)

    # Guardar landmarks como JSON
    landmarks_path = f"{filename_prefix}_landmarks.json"
    data = {
        'landmarks': landmarks,
        'detections': detections,
        'timestamp': timestamp,
        'source': source,
        'image_file': os.path.basename(image_path)
    }

    with open(landmarks_path, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"✅ Debug data saved:")
    print(f"   Image: {image_path}")
    print(f"   Landmarks: {landmarks_path}")
    print(f"   Detections: {detections}")

    return image_path, landmarks_path


def compare_landmarks(landmarks1, landmarks2):
    """
    Compara dos conjuntos de landmarks y retorna estadísticas de diferencia

    Args:
        landmarks1: Lista de 243 valores (móvil)
        landmarks2: Lista de 243 valores (escritorio)

    Returns:
        dict: Estadísticas de diferencia
    """
    import numpy as np

    arr1 = np.array(landmarks1)
    arr2 = np.array(landmarks2)

    # Calcular diferencias
    diff = np.abs(arr1 - arr2)

    stats = {
        'max_diff': float(np.max(diff)),
        'mean_diff': float(np.mean(diff)),
        'std_diff': float(np.std(diff)),
        'total_landmarks': len(landmarks1),
        'significant_diffs': int(np.sum(diff > 0.1)),  # Diferencias > 10%
    }

    # Identificar qué tipo de landmarks tienen más diferencias
    pose_diff = diff[:99].mean()  # Primeros 99 valores (pose)
    face_diff = diff[99:117].mean()  # Siguientes 18 valores (cara)
    lh_diff = diff[117:180].mean()  # Siguientes 63 valores (mano izq)
    rh_diff = diff[180:243].mean()  # Últimos 63 valores (mano der)

    stats['diff_by_type'] = {
        'pose': float(pose_diff),
        'face': float(face_diff),
        'left_hand': float(lh_diff),
        'right_hand': float(rh_diff)
    }

    return stats


if __name__ == "__main__":
    print("=" * 60)
    print("Debug Landmarks Comparison Tool")
    print("=" * 60)
    print()
    print("Este script proporciona funciones para guardar y comparar landmarks")
    print("entre la app móvil y el escritorio.")
    print()
    print("Para usarlo:")
    print("1. Importa este módulo en mediapipe_server.py")
    print("2. Llama a save_debug_data() en el endpoint /extract")
    print("3. Captura el mismo gesto en móvil y escritorio")
    print("4. Usa compare_landmarks() para analizar diferencias")
    print()
    print("=" * 60)
