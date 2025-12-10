"""
Convertir modelo Keras a TensorFlow Lite para Flutter

Este script convierte el modelo .keras a .tflite para usar en dispositivos móviles
"""

import tensorflow as tf
import numpy as np
import os
import sys

# Importar el cargador personalizado
from load_keras3_model import load_keras3_model

def convert_keras_to_tflite(keras_model_path, output_path):
    """
    Convierte un modelo Keras a TensorFlow Lite

    Args:
        keras_model_path: Ruta al archivo .keras
        output_path: Ruta donde guardar el archivo .tflite
    """
    print(f"[*] Cargando modelo desde: {keras_model_path}")

    # Cargar el modelo Keras
    model = load_keras3_model(keras_model_path)

    print(f"[+] Modelo cargado correctamente")
    print(f"    Input shape: {model.input_shape}")
    print(f"    Output shape: {model.output_shape}")

    # Guardar primero como SavedModel (más compatible con TFLite)
    temp_saved_model_dir = os.path.join(os.path.dirname(output_path), 'temp_saved_model')
    print(f"\n[*] Guardando como SavedModel temporal en: {temp_saved_model_dir}")
    model.export(temp_saved_model_dir)

    # Convertir a TensorFlow Lite desde SavedModel
    print(f"\n[*] Convirtiendo a TensorFlow Lite desde SavedModel...")
    converter = tf.lite.TFLiteConverter.from_saved_model(temp_saved_model_dir)

    # Sin optimizaciones (más compatible pero más grande)
    # converter.optimizations = [tf.lite.Optimize.DEFAULT]

    # Permitir operaciones SELECT_TF_OPS para mayor compatibilidad
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,  # Operaciones estándar de TFLite
        tf.lite.OpsSet.SELECT_TF_OPS     # Operaciones de TensorFlow (más compatibilidad)
    ]

    tflite_model = converter.convert()

    # Limpiar directorio temporal
    import shutil
    shutil.rmtree(temp_saved_model_dir)

    print(f"[+] Conversión exitosa!")
    print(f"    Tamaño del modelo TFLite: {len(tflite_model) / 1024 / 1024:.2f} MB")

    # Guardar el modelo TFLite
    print(f"\n[*] Guardando modelo TFLite en: {output_path}")
    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    print(f"[+] Modelo TFLite guardado correctamente")

    # Verificar el modelo TFLite
    print(f"\n[*] Verificando modelo TFLite...")
    interpreter = tf.lite.Interpreter(model_path=output_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"[+] Verificación exitosa!")
    print(f"    Input details: {input_details[0]['shape']}, dtype={input_details[0]['dtype']}")
    print(f"    Output details: {output_details[0]['shape']}, dtype={output_details[0]['dtype']}")

    # Probar con datos de ejemplo
    print(f"\n[*] Probando inferencia con datos de ejemplo...")
    test_input = np.random.randn(1, 65, 243).astype(np.float32)

    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    print(f"[+] Inferencia exitosa!")
    print(f"    Output shape: {output.shape}")
    print(f"    Suma de probabilidades: {output.sum():.4f} (debería ser ~1.0)")

    return True

if __name__ == '__main__':
    # Rutas
    base_dir = os.path.dirname(os.path.abspath(__file__))
    keras_model_path = os.path.join(base_dir, 'modelo_gestos_sin_patron_ceros.keras')
    tflite_model_path = os.path.join(base_dir, 'modelo_gestos.tflite')

    print("="*60)
    print("Convertidor de Keras a TensorFlow Lite")
    print("="*60 + "\n")

    if not os.path.exists(keras_model_path):
        print(f"❌ Error: No se encontró el modelo en {keras_model_path}")
        sys.exit(1)

    try:
        convert_keras_to_tflite(keras_model_path, tflite_model_path)
        print("\n" + "="*60)
        print("✅ CONVERSIÓN COMPLETADA")
        print("="*60)
        print(f"\nAhora copia estos archivos a la carpeta de assets de Flutter:")
        print(f"  1. {tflite_model_path}")
        print(f"  2. {os.path.join(base_dir, 'label_encoder.pkl')}")
        print(f"  3. {os.path.join(base_dir, 'normalizacion_sin_patron.pkl')}")

    except Exception as e:
        print(f"\n❌ Error durante la conversión: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
