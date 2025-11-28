const express = require('express');
const { getDB } = require('../config/database');

const router = express.Router();

// GET /api/gestos
router.get('/', async (req, res) => {
  try {
    const db = await getDB();
    const gestosCollection = db.collection('Gestos');

    // No devolver el contenido (GIFs), solo metadata
    const gestos = await gestosCollection
      .find({})
      .project({ contenido: 0 })
      .toArray();

    res.status(200).json(gestos);
  } catch (error) {
    console.error('❌ Error obteniendo gestos:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
