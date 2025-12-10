"""
Script para convertir modelo Keras 3.0 a formato H5 compatible con Keras 2.15
"""
import os
import sys
import io

# Configurar salida UTF-8 para Windows
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
except:
    pass

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'  # Silenciar advertencias

import json
import keras

print("Keras version:", keras.__version__)

# Cargar el modelo directamente desde el directorio Keras 3.0
model_dir = 'modelo_gestos_sin_patron_ceros.keras'
output_path = 'modelo_gestos_CONVERTED.h5'

try:
    # Usar el método especial de Keras 3 para cargar desde directorio
    print(f"\nCargando modelo Keras 3.0 desde directorio: {model_dir}")

    # Leer config
    with open(os.path.join(model_dir, 'config.json'), 'r') as f:
        config = json.load(f)

    print("Configuración del modelo cargada")
    print(f"  Clase: {config['class_name']}")
    print(f"  Capas: {len(config['config']['layers'])}")

    # Cargar el modelo con keras.saving (compatible con Keras 3)
    from keras import saving
    model = saving.load_model(model_dir)

    print(f"Modelo cargado exitosamente")
    print(f"Input shape: {model.input_shape}")
    print(f"Output shape: {model.output_shape}")

    # Guardar en formato H5
    print(f"\nGuardando modelo en formato H5: {output_path}")
    model.save(output_path, save_format='h5')
    print(f"Modelo convertido exitosamente a H5")

    # Verificar que el archivo se creó
    if os.path.exists(output_path):
        size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"Tamaño del archivo: {size_mb:.2f} MB")
    else:
        print("Error: El archivo H5 no se creó")

except Exception as e:
    print(f"Error durante la conversión: {e}")
    import traceback
    traceback.print_exc()
