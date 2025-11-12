import 'dart:io';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';

/// Script para descargar GIFs desde MongoDB y guardarlos como archivos locales
///
/// Uso: dart run download_gifs.dart
void main() async {
  // Configuración de MongoDB
  final mongoUri = 'mongodb+srv://angel_artu:Test123456@includesign.zz0yofi.mongodb.net/?retryWrites=true&w=majority&appName=inclusign';
  final databaseName = 'inclusign';

  print('🔄 Conectando a MongoDB...');

  final db = await Db.create(mongoUri);
  await db.open();

  print('✅ Conectado a MongoDB');
  print('📚 Base de datos: $databaseName');

  // Seleccionar base de datos
  final database = db.useDb(databaseName);

  // Crear directorios si no existen
  final abecedarioDir = Directory('inclusing_language_flutter/assets/gifs/abecedario');
  final gestosDir = Directory('inclusing_language_flutter/assets/gifs/gestos');

  if (!abecedarioDir.existsSync()) {
    abecedarioDir.createSync(recursive: true);
  }
  if (!gestosDir.existsSync()) {
    gestosDir.createSync(recursive: true);
  }

  print('\n📥 Descargando GIFs del Abecedario...');
  await downloadAbecedario(database, abecedarioDir);

  print('\n📥 Descargando GIFs de Gestos...');
  await downloadGestos(database, gestosDir);

  await db.close();
  print('\n✅ ¡Descarga completa!');
  print('📊 Resumen:');
  print('   - Abecedario: ${countFiles(abecedarioDir)} archivos');
  print('   - Gestos: ${countFiles(gestosDir)} archivos');
}

/// Descargar GIFs del abecedario
Future<void> downloadAbecedario(Db database, Directory outputDir) async {
  final collection = database.collection('Abecedario');
  final documents = await collection.find().toList();

  print('   Encontrados ${documents.length} documentos en Abecedario');

  int successCount = 0;
  int errorCount = 0;

  for (var doc in documents) {
    try {
      final letra = doc['letra'] ?? doc['nombre'];
      final contenidoBase64 = doc['contenido'];

      if (letra == null || contenidoBase64 == null) {
        print('   ⚠️  Documento sin letra o contenido: ${doc['_id']}');
        errorCount++;
        continue;
      }

      // Decodificar base64
      final bytes = base64Decode(contenidoBase64);

      // Guardar archivo
      final fileName = '$letra.gif';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      print('   ✅ $fileName (${_formatBytes(bytes.length)})');
      successCount++;
    } catch (e) {
      print('   ❌ Error procesando documento: $e');
      errorCount++;
    }
  }

  print('   📊 Exitosos: $successCount, Errores: $errorCount');
}

/// Descargar GIFs de gestos
Future<void> downloadGestos(Db database, Directory outputDir) async {
  final collection = database.collection('Gestos');
  final documents = await collection.find().toList();

  print('   Encontrados ${documents.length} documentos en Gestos');

  int successCount = 0;
  int errorCount = 0;

  for (var doc in documents) {
    try {
      final nombre = doc['nombre'];
      final contenidoBase64 = doc['contenido'];

      if (nombre == null || contenidoBase64 == null) {
        print('   ⚠️  Documento sin nombre o contenido: ${doc['_id']}');
        errorCount++;
        continue;
      }

      // Normalizar nombre: "BUENOS DIAS" -> "BUENOS_DIAS"
      final normalizedName = (nombre as String)
          .toUpperCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^A-Z0-9_]'), '');

      // Decodificar base64
      final bytes = base64Decode(contenidoBase64);

      // Guardar archivo
      final fileName = '$normalizedName.gif';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      print('   ✅ $fileName (${_formatBytes(bytes.length)})');
      successCount++;
    } catch (e) {
      print('   ❌ Error procesando "$doc['nombre']": $e');
      errorCount++;
    }
  }

  print('   📊 Exitosos: $successCount, Errores: $errorCount');
}

/// Contar archivos .gif en un directorio
int countFiles(Directory dir) {
  return dir
      .listSync()
      .where((entity) => entity is File && entity.path.endsWith('.gif'))
      .length;
}

/// Formatear bytes a formato legible
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
