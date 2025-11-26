const express = require('express');
const { getDB } = require('../config/database');

const router = express.Router();

// GET /api/abecedario
router.get('/', async (req, res) => {
  try {
    const db = getDB();
    const abecedarioCollection = db.collection('Abecedario');

    // No devolver el contenido (GIFs), solo metadata
    const abecedario = await abecedarioCollection
      .find({})
      .project({ contenido: 0 })
      .toArray();

    res.status(200).json(abecedario);
  } catch (error) {
    console.error('❌ Error obteniendo abecedario:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
