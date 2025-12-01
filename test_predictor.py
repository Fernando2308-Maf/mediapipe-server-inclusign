"""
Script para probar que el predictor se cargue correctamente con el nuevo modelo
"""
import sys
sys.path.append('django-rest-framework')

import numpy as np

print("=" * 70)
print("TEST DE CARGA DEL MODELO")
print("=" * 70)
print()

try:
    print("Importando modulos...")
    from api.services.predictor import model, encoder, classes, global_mean, global_std, num_features
    print("Importacion exitosa!")
    print()

    print("Informacion del Modelo:")
    print(f"   - Clases reconocidas: {len(classes)}")
    print(f"   - Features por frame: {num_features}")
    print(f"   - Forma de entrada esperada: (batch, 65, {num_features})")
    print()

    print("Gestos que el modelo puede reconocer:")
    for i, gesto in enumerate(classes, 1):
        print(f"   {i:2d}. {gesto}")
    print()

    print("El modelo se cargo correctamente!")
    print()
    print("=" * 70)

except Exception as e:
    print(f"Error al cargar el modelo: {e}")
    import traceback
    traceback.print_exc()
    print()
    print("=" * 70)
