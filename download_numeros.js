const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: './api_node/.env' });

const uri = process.env.MONGODB_URI;
const dbName = 'inclusign';

async function downloadNumeros() {
  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log('✅ Conectado a MongoDB');

    const db = client.db(dbName);
    const numerosCollection = db.collection('Numeros');

    // Obtener todos los números
    const numeros = await numerosCollection.find({}).toArray();
    console.log(`📊 Encontrados ${numeros.length} números en MongoDB`);

    // Crear carpeta si no existe
    const outputDir = path.join(__dirname, 'inclusing_language_flutter', 'assets', 'gifs', 'numeros');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log(`📁 Carpeta creada: ${outputDir}`);
    }

    // Descargar cada número
    for (const numero of numeros) {
      const numeroNombre = numero.numero || numero.nombre || numero._id;
      console.log(`\n📥 Descargando número: ${numeroNombre}`);

      if (!numero.contenido) {
        console.log(`⚠️  No hay contenido para ${numeroNombre}`);
        continue;
      }

      // Extraer el base64 (quitar el prefijo data:image/gif;base64, si existe)
      let base64Data = numero.contenido;
      if (base64Data.includes('base64,')) {
        base64Data = base64Data.split('base64,')[1];
      }

      // Convertir base64 a buffer
      const buffer = Buffer.from(base64Data, 'base64');

      // Guardar archivo
      const fileName = `${numeroNombre}.gif`;
      const filePath = path.join(outputDir, fileName);
      fs.writeFileSync(filePath, buffer);

      console.log(`   ✅ Guardado: ${fileName} (${(buffer.length / 1024).toFixed(2)} KB)`);
    }

    console.log('\n🎉 ¡Todos los GIFs de números han sido descargados!');
    console.log(`📂 Ubicación: ${outputDir}`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

downloadNumeros();
