#!/usr/bin/env python3
"""
Script para descargar GIFs desde MongoDB y guardarlos como archivos locales
Uso: python download_gifs.py
"""

import base64
import os
from pymongo import MongoClient

# Configuración
MONGO_URI = "mongodb+srv://angel_artu:Test123456@includesign.zz0yofi.mongodb.net/?retryWrites=true&w=majority&appName=inclusign"
DATABASE_NAME = "inclusign"

# Directorios de salida
ABECEDARIO_DIR = "inclusing_language_flutter/assets/gifs/abecedario"
GESTOS_DIR = "inclusing_language_flutter/assets/gifs/gestos"

def format_bytes(bytes):
    """Formatear bytes a formato legible"""
    if bytes < 1024:
        return f"{bytes} B"
    elif bytes < 1024 * 1024:
        return f"{bytes / 1024:.1f} KB"
    else:
        return f"{bytes / (1024 * 1024):.1f} MB"

def download_abecedario(collection, output_dir):
    """Descargar GIFs del abecedario"""
    print(f"\n[>>] Descargando GIFs del Abecedario...")

    documents = list(collection.find())
    print(f"   Encontrados {len(documents)} documentos")

    success_count = 0
    error_count = 0

    for doc in documents:
        try:
            letra = doc.get('letra') or doc.get('nombre')
            contenido_base64 = doc.get('contenido')

            if not letra or not contenido_base64:
                print(f"   [!] Documento sin letra o contenido")
                error_count += 1
                continue

            # Decodificar base64
            gif_bytes = base64.b64decode(contenido_base64)

            # Guardar archivo
            filename = f"{letra}.gif"
            filepath = os.path.join(output_dir, filename)

            with open(filepath, 'wb') as f:
                f.write(gif_bytes)

            print(f"   [OK] {filename} ({format_bytes(len(gif_bytes))})")
            success_count += 1

        except Exception as e:
            print(f"   [ERROR] {e}")
            error_count += 1

    print(f"   [RESUMEN] Exitosos: {success_count}, Errores: {error_count}")

def download_gestos(collection, output_dir):
    """Descargar GIFs de gestos"""
    print(f"\n[>>] Descargando GIFs de Gestos...")

    documents = list(collection.find())
    print(f"   Encontrados {len(documents)} documentos")

    success_count = 0
    error_count = 0

    for doc in documents:
        try:
            nombre = doc.get('nombre')
            contenido_base64 = doc.get('contenido')

            if not nombre or not contenido_base64:
                print(f"   [!] Documento sin nombre o contenido")
                error_count += 1
                continue

            # Normalizar nombre: "BUENOS DIAS" -> "BUENOS_DIAS"
            normalized_name = nombre.upper().replace(' ', '_')
            # Remover caracteres especiales
            normalized_name = ''.join(c for c in normalized_name if c.isalnum() or c == '_')

            # Decodificar base64
            gif_bytes = base64.b64decode(contenido_base64)

            # Guardar archivo
            filename = f"{normalized_name}.gif"
            filepath = os.path.join(output_dir, filename)

            with open(filepath, 'wb') as f:
                f.write(gif_bytes)

            print(f"   [OK] {filename} ({format_bytes(len(gif_bytes))})")
            success_count += 1

        except Exception as e:
            print(f"   [ERROR] Error en '{nombre}': {e}")
            error_count += 1

    print(f"   [RESUMEN] Exitosos: {success_count}, Errores: {error_count}")

def count_files(directory):
    """Contar archivos .gif en un directorio"""
    try:
        return len([f for f in os.listdir(directory) if f.endswith('.gif')])
    except:
        return 0

def main():
    print("[*] Conectando a MongoDB...")

    # Conectar a MongoDB
    client = MongoClient(MONGO_URI)
    db = client[DATABASE_NAME]

    print(f"[OK] Conectado a MongoDB")
    print(f"[*] Base de datos: {DATABASE_NAME}")

    # Crear directorios si no existen
    os.makedirs(ABECEDARIO_DIR, exist_ok=True)
    os.makedirs(GESTOS_DIR, exist_ok=True)

    try:
        # Descargar abecedario
        abecedario_collection = db['Abecedario']
        download_abecedario(abecedario_collection, ABECEDARIO_DIR)

        # Descargar gestos
        gestos_collection = db['Gestos']
        download_gestos(gestos_collection, GESTOS_DIR)

    except Exception as e:
        print(f"\n[ERROR] Error general: {e}")
    finally:
        client.close()
        print(f"\n[OK] Descarga completa!")
        print(f"[*] Resumen:")
        print(f"   - Abecedario: {count_files(ABECEDARIO_DIR)} archivos")
        print(f"   - Gestos: {count_files(GESTOS_DIR)} archivos")

if __name__ == "__main__":
    main()
