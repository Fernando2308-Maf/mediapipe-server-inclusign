import pickle
import numpy as np

# Cargar el normalizador
scaler = pickle.load(open('normalizacion_sin_patron.pkl', 'rb'))

print("=" * 60)
print("INSPECCION DEL NORMALIZADOR")
print("=" * 60)
print()
print(f"Tipo: {type(scaler)}")
print(f"Keys: {list(scaler.keys())}")
print()

for key, value in scaler.items():
    print(f"{key}:")
    print(f"  Tipo: {type(value)}")
    if hasattr(value, 'shape'):
        print(f"  Shape: {value.shape}")
        print(f"  Primeros 5 valores: {value[:5]}")
    else:
        print(f"  Valor: {value}")
    print()
