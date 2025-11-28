const express = require('express');
const { getDB } = require('../config/database');

const router = express.Router();

// GET /api/niveles
router.get('/', async (req, res) => {
  try {
    const db = await getDB();
    const nivelesCollection = db.collection('Niveles');

    const niveles = await nivelesCollection.find({}).sort({ nivelID: 1 }).toArray();

    res.status(200).json(niveles);
  } catch (error) {
    console.error('❌ Error obteniendo niveles:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/niveles/:nivelID
router.get('/:nivelID', async (req, res) => {
  try {
    const nivelID = parseInt(req.params.nivelID);
    const db = await getDB();
    const nivelesCollection = db.collection('Niveles');

    const nivel = await nivelesCollection.findOne({ nivelID });

    if (!nivel) {
      return res.status(404).json({ message: 'Nivel no encontrado' });
    }

    res.status(200).json(nivel);
  } catch (error) {
    console.error('❌ Error obteniendo nivel:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
