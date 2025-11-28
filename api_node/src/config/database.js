const { MongoClient } = require('mongodb');

let db = null;
let client = null;

async function connectDB() {
  if (db) return db;

  try {
    const uri = process.env.MONGODB_URI;
    const dbName = process.env.DATABASE_NAME || 'inclusign';

    console.log('🔌 Conectando a MongoDB Atlas...');

    client = new MongoClient(uri, {
      serverSelectionTimeoutMS: 30000,
      connectTimeoutMS: 30000,
    });

    await client.connect();
    db = client.db(dbName);

    console.log('✅ Conexión exitosa a MongoDB Atlas');
    console.log(`📚 Base de datos: ${dbName}`);

    return db;
  } catch (error) {
    console.error('❌ Error conectando a MongoDB:', error);
    throw error;
  }
}

async function getDB() {
  if (!db) {
    // En Vercel serverless, auto-conectar si no hay conexión
    console.log('⚠️ DB no inicializada, conectando automáticamente...');
    await connectDB();
  }
  return db;
}

async function closeDB() {
  if (client) {
    await client.close();
    db = null;
    client = null;
    console.log('🔌 Conexión a MongoDB cerrada');
  }
}

module.exports = { connectDB, getDB, closeDB };
