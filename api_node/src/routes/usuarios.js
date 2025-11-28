const express = require('express');
const { getDB } = require('../config/database');
const { hashPassword } = require('../utils/auth');

const router = express.Router();

// GET /api/usuarios/:usuarioID
router.get('/:usuarioID', async (req, res) => {
  try {
    const { usuarioID } = req.params;
    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');

    const usuario = await usuariosCollection.findOne({ usuarioID });

    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // No devolver la contraseña
    delete usuario.pass;
    delete usuario.contrasenaHash;

    res.status(200).json(usuario);
  } catch (error) {
    console.error('❌ Error obteniendo usuario:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/usuarios/by-email/:email
router.get('/by-email/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');

    const usuario = await usuariosCollection.findOne({ correo: email });

    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // No devolver la contraseña
    delete usuario.pass;
    delete usuario.contrasenaHash;

    res.status(200).json(usuario);
  } catch (error) {
    console.error('❌ Error obteniendo usuario por email:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/usuarios/:usuarioID/password - Actualizar contraseña
router.put('/:usuarioID/password', async (req, res) => {
  try {
    const { usuarioID } = req.params;
    const { currentPassword, newPassword } = req.body;

    // Validar que se enviaron todos los campos requeridos
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        message: 'Se requieren la contraseña actual y la nueva contraseña'
      });
    }

    const db = await getDB();
    const usuariosCollection = db.collection('Usuarios');

    // Obtener el usuario
    const usuario = await usuariosCollection.findOne({ usuarioID });

    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Verificar que la contraseña actual es correcta
    const currentPasswordHash = hashPassword(currentPassword);
    console.log('🔐 Validando contraseña para usuario:', usuario.correo);
    console.log('   Hash recibido:', currentPasswordHash);
    console.log('   Hash en BD:', usuario.pass);
    console.log('   ¿Coinciden?:', currentPasswordHash === usuario.pass);

    if (currentPasswordHash !== usuario.pass) {
      console.log('❌ Contraseña actual incorrecta');
      return res.status(401).json({ message: 'Contraseña actual incorrecta' });
    }
    console.log('✅ Contraseña actual correcta');

    // Hashear la nueva contraseña
    const newPasswordHash = hashPassword(newPassword);

    // Actualizar la contraseña en la base de datos
    const result = await usuariosCollection.updateOne(
      { usuarioID },
      { $set: { pass: newPasswordHash } }
    );

    if (result.modifiedCount === 0) {
      return res.status(500).json({ message: 'No se pudo actualizar la contraseña' });
    }

    console.log(`✅ Contraseña actualizada para usuario: ${usuario.correo}`);
    res.status(200).json({ message: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    console.error('❌ Error actualizando contraseña:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
