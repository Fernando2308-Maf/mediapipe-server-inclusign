const express = require('express');
const { getDB } = require('../config/database');
const { generateUsuarioID, hashPassword, verifyPassword, generateToken } = require('../utils/auth');

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { email, password, username, firstName } = req.body;

    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');

    // Verificar si el correo ya existe
    const existingUser = await usuariosCollection.findOne({ correo: email });
    if (existingUser) {
      return res.status(400).json({
        isSuccess: false,
        errorMessage: 'El correo electrónico ya está registrado',
      });
    }

    // Generar usuarioID único
    const usuarioID = generateUsuarioID();
    const nombre = username || firstName;

    // Formato de fecha simple YYYY-MM-DD
    const now = new Date();
    const fechaRegistro = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    // Crear nuevo usuario
    const usuario = {
      usuarioID,
      nombre,
      correo: email,
      fechaRegistro,
      pass: hashPassword(password),
    };

    await usuariosCollection.insertOne(usuario);

    // Crear progresión inicial
    const progresion = {
      usuarioID,
      nivelActual: 1,
      nivelesCompletados: [],
      estadisticas: {
        totalExitos: 0,
        totalFallos: 0,
        totalIntentos: 0,
      },
      experienciaTotal: 0,
      ultimaActividad: fechaRegistro,
      racha: 1,
      ultimoAcceso: now.toISOString(),
    };

    const progresionesCollection = db.collection('Progresion');
    await progresionesCollection.insertOne(progresion);

    // Generar token
    const token = generateToken(usuarioID);

    res.status(200).json({
      isSuccess: true,
      token,
      usuarioID,
      userProfile: {
        email,
        firstName: nombre,
        level: 1,
        experience: 0,
        streak: 1,
        completedLessons: [],
      },
    });
  } catch (error) {
    console.error('❌ Error en registro:', error);
    res.status(500).json({
      isSuccess: false,
      errorMessage: `Error en el registro: ${error.message}`,
    });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log('📧 Intentando login para:', email);

    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');

    // Buscar usuario por correo
    const usuarioDoc = await usuariosCollection.findOne({ correo: email });

    if (!usuarioDoc) {
      console.log('❌ Usuario no encontrado:', email);
      return res.status(404).json({
        isSuccess: false,
        errorMessage: 'Usuario no encontrado',
      });
    }

    console.log('✅ Usuario encontrado:', usuarioDoc.nombre);

    // Verificar contraseña
    const passwordHash = usuarioDoc.pass || usuarioDoc.contrasenaHash;
    if (!passwordHash || !verifyPassword(password, passwordHash)) {
      console.log('❌ Contraseña incorrecta');
      return res.status(401).json({
        isSuccess: false,
        errorMessage: 'Contraseña incorrecta',
      });
    }

    console.log('✅ Contraseña correcta');

    const usuarioID = usuarioDoc.usuarioID.toString();
    const nombre = usuarioDoc.nombre.toString();
    const correo = usuarioDoc.correo.toString();

    // Obtener progresión
    const progresionesCollection = db.collection('Progresion');
    let progresionDoc = await progresionesCollection.findOne({ usuarioID });

    // Crear progresión si no existe
    if (!progresionDoc) {
      const now = new Date();
      const fechaActividad = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

      progresionDoc = {
        usuarioID,
        nivelActual: 1,
        nivelesCompletados: [],
        estadisticas: {
          totalExitos: 0,
          totalFallos: 0,
          totalIntentos: 0,
        },
        experienciaTotal: 0,
        ultimaActividad: fechaActividad,
        racha: 1,
        ultimoAcceso: now.toISOString(),
      };
      await progresionesCollection.insertOne(progresionDoc);
    } else {
      // Actualizar racha según el último acceso
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      let ultimoAcceso = progresionDoc.ultimoAcceso ? new Date(progresionDoc.ultimoAcceso) : null;
      let nuevaRacha = progresionDoc.racha || 0;

      if (ultimoAcceso) {
        const lastAccessDay = new Date(ultimoAcceso.getFullYear(), ultimoAcceso.getMonth(), ultimoAcceso.getDate());
        const daysDifference = Math.floor((today - lastAccessDay) / (1000 * 60 * 60 * 24));

        if (daysDifference === 1) {
          // Último acceso fue ayer, incrementar racha
          nuevaRacha++;
          console.log(`🔥 Racha incrementada: ${nuevaRacha - 1} → ${nuevaRacha}`);
        } else if (daysDifference > 1) {
          // Último acceso fue hace más de un día, resetear racha
          console.log(`💔 Racha perdida (${progresionDoc.racha} días)`);
          nuevaRacha = 1;
        } else if (daysDifference === 0) {
          // Último acceso fue hoy, mantener racha
          console.log(`✅ Acceso del mismo día - Racha actual: ${nuevaRacha} días`);
        }
      } else {
        // Primera vez que se registra racha
        nuevaRacha = 1;
        console.log('🎉 Iniciando racha por primera vez');
      }

      // Actualizar racha y último acceso en la base de datos
      await progresionesCollection.updateOne(
        { usuarioID },
        { $set: { racha: nuevaRacha, ultimoAcceso: now.toISOString() } }
      );

      progresionDoc.racha = nuevaRacha;
      progresionDoc.ultimoAcceso = now.toISOString();
    }

    // Convertir nivelesCompletados a lista de enteros
    const completedLessons = (progresionDoc.nivelesCompletados || []).map((e) => {
      if (typeof e === 'number') return e;
      if (typeof e === 'string') return parseInt(e) || 0;
      return 0;
    });

    // Generar token
    const token = generateToken(usuarioID);

    const level = typeof progresionDoc.nivelActual === 'number' ? progresionDoc.nivelActual : 1;
    const experience = typeof progresionDoc.experienciaTotal === 'number' ? progresionDoc.experienciaTotal : 0;
    const racha = progresionDoc.racha || 0;

    res.status(200).json({
      isSuccess: true,
      token,
      usuarioID,
      userProfile: {
        email: correo,
        firstName: nombre,
        level,
        experience,
        streak: racha,
        completedLessons,
      },
    });
  } catch (error) {
    console.error('❌ Error en login:', error);
    res.status(500).json({
      isSuccess: false,
      errorMessage: `Error en el login: ${error.message}`,
    });
  }
});

// POST /api/auth/register-google
router.post('/register-google', async (req, res) => {
  try {
    const { email, nombre, photoUrl, loginMethod } = req.body;

    console.log('🌍 Intentando login/registro con Google para:', email);

    if (!email) {
      return res.status(400).json({ isSuccess: false, message: 'El email es obligatorio' });
    }

    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');
    const progresionesCollection = db.collection('Progresion');

    // 1. Buscar si el usuario ya existe
    let usuarioDoc = await usuariosCollection.findOne({ correo: email });
    const now = new Date();
    
    let usuarioID;
    let racha = 0;
    let progresionDoc;
    let isNewUser = false;

    if (usuarioDoc) {
      console.log('✅ Usuario de Google ya existía. Iniciando sesión.');
      usuarioID = usuarioDoc.usuarioID.toString();
      
      progresionDoc = await progresionesCollection.findOne({ usuarioID });
      
      if (progresionDoc) {
        // Lógica de racha igual que en login normal
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        let ultimoAcceso = progresionDoc.ultimoAcceso ? new Date(progresionDoc.ultimoAcceso) : null;
        racha = progresionDoc.racha || 0;

        if (ultimoAcceso) {
          const lastAccessDay = new Date(ultimoAcceso.getFullYear(), ultimoAcceso.getMonth(), ultimoAcceso.getDate());
          const daysDifference = Math.floor((today - lastAccessDay) / (1000 * 60 * 60 * 24));
          if (daysDifference === 1) { racha++; } 
          else if (daysDifference > 1) { racha = 1; }
        } else {
          racha = 1;
        }

        await progresionesCollection.updateOne(
          { usuarioID },
          { $set: { racha: racha, ultimoAcceso: now.toISOString() } }
        );
      }
    } else {
      console.log('🆕 Creando nuevo usuario desde Google');
      isNewUser = true;
      usuarioID = generateUsuarioID();
      const fechaRegistro = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

      usuarioDoc = {
        usuarioID,
        nombre: nombre || 'Usuario de Google',
        correo: email,
        fotoPerfil: photoUrl,
        loginMethod: loginMethod || 'google',
        fechaRegistro,
        // No guardamos contraseña porque el login es delegado a Google
      };
      await usuariosCollection.insertOne(usuarioDoc);

      progresionDoc = {
        usuarioID,
        nivelActual: 1,
        nivelesCompletados: [],
        estadisticas: { totalExitos: 0, totalFallos: 0, totalIntentos: 0 },
        experienciaTotal: 0,
        ultimaActividad: fechaRegistro,
        racha: 1,
        ultimoAcceso: now.toISOString(),
      };
      await progresionesCollection.insertOne(progresionDoc);
      racha = 1;
    }

    const token = generateToken(usuarioID);
    
    const completedLessons = progresionDoc && progresionDoc.nivelesCompletados 
      ? progresionDoc.nivelesCompletados.map(e => parseInt(e) || 0) 
      : [];

    const level = progresionDoc ? (parseInt(progresionDoc.nivelActual) || 1) : 1;
    const experience = progresionDoc ? (parseInt(progresionDoc.experienciaTotal) || 0) : 0;

    res.status(200).json({
      isSuccess: true,
      token,
      usuarioID,
      isNewUser,
      userProfile: {
        email: usuarioDoc.correo,
        firstName: usuarioDoc.nombre,
        level,
        experience,
        streak: racha,
        completedLessons,
      },
    });

  } catch (error) {
    console.error('❌ Error en Google Sign In:', error);
    res.status(500).json({
      isSuccess: false,
      message: `Error al conectar con Google: ${error.message}`,
    });
  }
});

// POST /api/auth/sync-google
router.post('/sync-google', async (req, res) => {
  try {
    const { usuarioID, googleEmail, displayName } = req.body;
    
    if (!usuarioID || !googleEmail) {
      return res.status(400).json({ isSuccess: false, message: 'Datos incompletos' });
    }

    const db = await getDB();
    await db.collection('Usuarios').updateOne(
      { usuarioID: usuarioID.toString() },
      { $set: { googleEmail, loginMethod: 'google' } }
    );
    
    res.status(200).json({ isSuccess: true });
  } catch (error) {
    console.error('❌ Error al sincronizar Google:', error);
    res.status(500).json({ isSuccess: false });
  }
});

module.exports = router;
