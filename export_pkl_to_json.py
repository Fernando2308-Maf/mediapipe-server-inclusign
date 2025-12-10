"""
Exportar archivos PKL a JSON para Flutter

Convierte los archivos label_encoder.pkl y normalizacion_sin_patron.pkl
a formato JSON para que Flutter pueda leerlos
"""

import pickle
import json
import numpy as np
import os

def export_label_encoder(pkl_path, json_path):
    """Exporta el label encoder a JSON"""
    print(f"[*] Cargando label encoder desde: {pkl_path}")

    with open(pkl_path, 'rb') as f:
        label_encoder = pickle.load(f)

    # Extraer las clases
    classes = label_encoder.classes_.tolist()

    data = {
        "classes": classes,
        "num_classes": len(classes)
    }

    print(f"[+] Label encoder cargado: {len(classes)} clases")
    print(f"    Clases: {', '.join(classes[:5])}...")

    # Guardar como JSON
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"[+] Guardado en: {json_path}")
    return True

def export_scaler(pkl_path, json_path):
    """Exporta el scaler (diccionario con mean y std globales) a JSON"""
    print(f"\n[*] Cargando scaler desde: {pkl_path}")

    with open(pkl_path, 'rb') as f:
        scaler = pickle.load(f)

    # El scaler es un diccionario con mean, std, etc.
    data = {
        "mean": scaler['mean'],
        "std": scaler['std'],
        "num_frames": scaler['num_frames'],
        "num_landmarks": scaler['num_landmarks'],
        "num_features": scaler['num_features'],
        "umbral_ceros": scaler['umbral_ceros'],
        "preprocessing": scaler['preprocessing']
    }

    print(f"[+] Scaler cargado")
    print(f"    Mean: {data['mean']}")
    print(f"    Std: {data['std']}")
    print(f"    Features: {data['num_features']}")
    print(f"    Preprocessing: {data['preprocessing']}")

    # Guardar como JSON
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

    print(f"[+] Guardado en: {json_path}")
    return True

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))

    print("="*60)
    print("Exportador de PKL a JSON para Flutter")
    print("="*60)

    # Exportar label encoder
    label_encoder_pkl = os.path.join(base_dir, 'label_encoder.pkl')
    label_encoder_json = os.path.join(base_dir, 'label_encoder.json')

    if os.path.exists(label_encoder_pkl):
        export_label_encoder(label_encoder_pkl, label_encoder_json)
    else:
        print(f"❌ No se encontró: {label_encoder_pkl}")

    # Exportar scaler
    scaler_pkl = os.path.join(base_dir, 'normalizacion_sin_patron.pkl')
    scaler_json = os.path.join(base_dir, 'scaler.json')

    if os.path.exists(scaler_pkl):
        export_scaler(scaler_pkl, scaler_json)
    else:
        print(f"❌ No se encontró: {scaler_pkl}")

    print("\n" + "="*60)
    print("✅ EXPORTACIÓN COMPLETADA")
    print("="*60)
    print("\nArchivos generados:")
    print(f"  1. {label_encoder_json}")
    print(f"  2. {scaler_json}")
    print(f"\nAhora copia estos archivos junto con modelo_gestos.tflite a:")
    print(f"  inclusing_language_flutter/assets/ml/")
