#!/usr/bin/env python3
"""
Script para exportar GIFs desde MongoDB y guardarlos como archivos locales
Uso: python exportar_gifs_desde_mongodb.py
"""

import base64
import os
from pymongo import MongoClient

# ============================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================

# Tu connection string de MongoDB Atlas
MONGO_URI = "mongodb+srv://usuario:password@cluster.mongodb.net/inclusign?retryWrites=true&w=majority"

# Nombre de la base de datos
DATABASE_NAME = "inclusign"

# Rutas donde se guardarán los GIFs
OUTPUT_DIR_ABECEDARIO = "./abecedario"
OUTPUT_DIR_GESTOS = "./gestos"

# ============================================
# SCRIPT
# ============================================

def exportar_abecedario(db):
    """Exporta los GIFs del abecedario"""
    print("\n📚 Exportando ABECEDARIO...")

    collection = db["Abecedario"]
    documentos = collection.find()

    os.makedirs(OUTPUT_DIR_ABECEDARIO, exist_ok=True)

    count = 0
    for doc in documentos:
        nombre = doc.get("nombre", "")
        contenido_base64 = doc.get("contenido", "")

        if not nombre or not contenido_base64:
            print(f"  ⚠️  Documento sin nombre o contenido: {doc.get('_id')}")
            continue

        # Decodificar base64
        try:
            gif_bytes = base64.b64decode(contenido_base64)

            # Guardar archivo
            filename = f"{nombre}.gif"
            filepath = os.path.join(OUTPUT_DIR_ABECEDARIO, filename)

            with open(filepath, "wb") as f:
                f.write(gif_bytes)

            count += 1
            print(f"  ✅ {count}. {filename} ({len(gif_bytes):,} bytes)")

        except Exception as e:
            print(f"  ❌ Error con {nombre}: {e}")

    print(f"\n✅ Abecedario completado: {count} archivos exportados")
    return count


def exportar_gestos(db):
    """Exporta los GIFs de los gestos"""
    print("\n🎭 Exportando GESTOS...")

    collection = db["Gestos"]
    documentos = collection.find()

    os.makedirs(OUTPUT_DIR_GESTOS, exist_ok=True)

    count = 0
    for doc in documentos:
        nombre = doc.get("nombre", "")
        contenido_base64 = doc.get("contenido", "")

        if not nombre or not contenido_base64:
            print(f"  ⚠️  Documento sin nombre o contenido: {doc.get('_id')}")
            continue

        # Normalizar nombre: "BUENOS DIAS" -> "BUENOS_DIAS"
        nombre_archivo = nombre.replace(" ", "_").upper()

        # Decodificar base64
        try:
            gif_bytes = base64.b64decode(contenido_base64)

            # Guardar archivo
            filename = f"{nombre_archivo}.gif"
            filepath = os.path.join(OUTPUT_DIR_GESTOS, filename)

            with open(filepath, "wb") as f:
                f.write(gif_bytes)

            count += 1
            print(f"  ✅ {count}. {filename} ({len(gif_bytes):,} bytes)")

        except Exception as e:
            print(f"  ❌ Error con {nombre}: {e}")

    print(f"\n✅ Gestos completados: {count} archivos exportados")
    return count


def main():
    print("=" * 60)
    print("🚀 EXPORTADOR DE GIFs DESDE MONGODB")
    print("=" * 60)

    try:
        # Conectar a MongoDB
        print(f"\n🔌 Conectando a MongoDB...")
        client = MongoClient(MONGO_URI)
        db = client[DATABASE_NAME]

        # Verificar conexión
        client.admin.command('ping')
        print("✅ Conectado exitosamente a MongoDB")

        # Exportar abecedario
        count_abecedario = exportar_abecedario(db)

        # Exportar gestos
        count_gestos = exportar_gestos(db)

        # Resumen
        print("\n" + "=" * 60)
        print("🎉 EXPORTACIÓN COMPLETADA")
        print("=" * 60)
        print(f"📝 Abecedario: {count_abecedario} archivos en {OUTPUT_DIR_ABECEDARIO}/")
        print(f"🎬 Gestos: {count_gestos} archivos en {OUTPUT_DIR_GESTOS}/")
        print(f"📦 Total: {count_abecedario + count_gestos} archivos exportados")
        print("\n📋 Próximos pasos:")
        print("1. Copia los archivos de ./abecedario/ a assets/gifs/abecedario/")
        print("2. Copia los archivos de ./gestos/ a assets/gifs/gestos/")
        print("3. Ejecuta: flutter pub get")
        print("4. Ejecuta: flutter run")

        client.close()

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\nVerifica:")
        print("1. Tu connection string de MongoDB es correcta")
        print("2. Tienes instalado pymongo: pip install pymongo")
        print("3. Tu IP está en la whitelist de MongoDB Atlas")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
