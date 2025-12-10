"""
Cargador personalizado para modelos Keras 3.0 cuando hay problemas de permisos

Este script reconstruye el modelo desde config.json y carga los pesos desde model.weights.h5
"""

import json
import tensorflow as tf
from tensorflow import keras
import os

def load_keras3_model(model_dir):
    """
    Carga un modelo Keras 3.0 desde un directorio

    Args:
        model_dir: Ruta al directorio .keras

    Returns:
        Modelo de Keras cargado
    """
    # Leer configuración
    config_path = os.path.join(model_dir, 'config.json')
    weights_path = os.path.join(model_dir, 'model.weights.h5')

    print(f"[*] Leyendo configuracion desde: {config_path}")
    with open(config_path, 'r') as f:
        config = json.load(f)

    # Reconstruir modelo desde configuración
    print(f"[*] Reconstruyendo modelo: {config['class_name']}")

    # Extraer capas
    layers_config = config['config']['layers']

    # Crear modelo secuencial
    model = keras.Sequential()

    for layer_config in layers_config:
        layer_class = layer_config['class_name']
        layer_params = layer_config['config']

        print(f"   Agregando capa: {layer_class}")

        # Crear capa según el tipo
        if layer_class == 'InputLayer':
            # Skip, se maneja automáticamente
            continue
        elif layer_class == 'Bidirectional':
            # Extraer configuración de la capa LSTM interna
            inner_layer_config = layer_params['layer']['config']
            model.add(keras.layers.Bidirectional(
                keras.layers.LSTM(
                    units=inner_layer_config['units'],
                    return_sequences=inner_layer_config.get('return_sequences', False)
                ),
                name=layer_params.get('name')
            ))
        elif layer_class == 'BatchNormalization':
            model.add(keras.layers.BatchNormalization(
                name=layer_params.get('name')
            ))
        elif layer_class == 'LSTM':
            model.add(keras.layers.LSTM(
                units=layer_params['units'],
                return_sequences=layer_params.get('return_sequences', False),
                name=layer_params.get('name')
            ))
        elif layer_class == 'Dense':
            activation = layer_params.get('activation', 'linear')
            model.add(keras.layers.Dense(
                units=layer_params['units'],
                activation=activation,
                name=layer_params.get('name')
            ))
        elif layer_class == 'Dropout':
            model.add(keras.layers.Dropout(
                rate=layer_params['rate'],
                name=layer_params.get('name')
            ))
        else:
            print(f"   [!] Capa desconocida: {layer_class}")

    # Construir modelo con shape de entrada correcta
    # El modelo espera (batch_size, 65, 243) pero queremos (None, 65, 243)
    input_shape = config['config']['layers'][0]['config']['batch_shape']
    # Extraer solo las dimensiones de secuencia (65, 243), ignorar batch_size
    if input_shape[0] is not None:
        # Tiene batch_size fijo, usar solo las dimensiones de datos
        input_shape = input_shape[1:]
    else:
        # Ya tiene None como batch, quitar el None
        input_shape = input_shape[1:]

    print(f"[*] Construyendo modelo con input shape: (None, {input_shape[0]}, {input_shape[1]})")
    model.build((None, input_shape[0], input_shape[1]))

    # Cargar pesos
    print(f"[*] Cargando pesos desde: {weights_path}")
    model.load_weights(weights_path)

    print(f"[+] Modelo cargado exitosamente!")
    print(f"   Input shape: {model.input_shape}")
    print(f"   Output shape: {model.output_shape}")

    return model

if __name__ == "__main__":
    # Prueba
    model_dir = "modelo_gestos_sin_patron_ceros.keras"
    model = load_keras3_model(model_dir)

    print("\n" + "="*60)
    print("Resumen del modelo:")
    print("="*60)
    model.summary()
