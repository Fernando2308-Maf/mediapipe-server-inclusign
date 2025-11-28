require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { connectDB } = require('./src/config/database');

// Importar rutas
const authRoutes = require('./src/routes/auth');
const progresionRoutes = require('./src/routes/progresion');
const usuariosRoutes = require('./src/routes/usuarios');
const nivelesRoutes = require('./src/routes/niveles');
const abecedarioRoutes = require('./src/routes/abecedario');
const gestosRoutes = require('./src/routes/gestos');

const app = express();
const PORT = process.env.PORT || 5246;

// Middleware
app.use(cors()); // Permitir CORS para todas las solicitudes
app.use(express.json({ limit: '50mb' })); // Parsear JSON con límite aumentado
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Ruta raíz
app.get('/', (req, res) => {
  res.json({
    message: '✅ API Inclusign funcionando correctamente',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      progresion: '/api/progresion',
      usuarios: '/api/usuarios',
      niveles: '/api/niveles',
      abecedario: '/api/abecedario',
      gestos: '/api/gestos',
    },
  });
});

// Montar rutas
app.use('/api/auth', authRoutes);
app.use('/api/progresion', progresionRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/niveles', nivelesRoutes);
app.use('/api/abecedario', abecedarioRoutes);
app.use('/api/gestos', gestosRoutes);

// Conectar a MongoDB al iniciar
connectDB().catch(err => {
  console.error('❌ Error conectando a MongoDB:', err);
});

// Iniciar servidor solo si no estamos en Vercel
if (process.env.VERCEL !== '1') {
  app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
    console.log(`📡 API disponible en http://localhost:${PORT}/api`);
  });
}

// Exportar para Vercel
module.exports = app;
