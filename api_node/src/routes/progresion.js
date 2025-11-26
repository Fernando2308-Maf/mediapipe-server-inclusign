const express = require('express');
const { getDB } = require('../config/database');

const router = express.Router();

// GET /api/progresion/:usuarioID
router.get('/:usuarioID', async (req, res) => {
  try {
    const { usuarioID } = req.params;
    const db = getDB();
    const progresionesCollection = db.collection('Progresion');

    let progresion = await progresionesCollection.findOne({ usuarioID });

    // Crear progresión si no existe
    if (!progresion) {
      progresion = {
        usuarioID,
        nivelActual: 1,
        nivelesCompletados: [],
        estadisticas: {
          totalExitos: 0,
          totalFallos: 0,
          totalIntentos: 0,
        },
        experienciaTotal: 0,
        leccionesCompletadasHoy: 0,
        ultimaActualizacionDiaria: new Date().toISOString(),
        ultimaActividad: new Date().toISOString(),
        racha: 0,
        ultimoAcceso: null,
      };
      await progresionesCollection.insertOne(progresion);
    } else {
      // Migración: Agregar campos nuevos si no existen
      let needsUpdate = false;
      if (!('leccionesCompletadasHoy' in progresion)) {
        progresion.leccionesCompletadasHoy = 0;
        needsUpdate = true;
      }
      if (!('ultimaActualizacionDiaria' in progresion)) {
        progresion.ultimaActualizacionDiaria = new Date().toISOString();
        needsUpdate = true;
      }
      if (!('racha' in progresion)) {
        progresion.racha = 0;
        needsUpdate = true;
      }
      if (!('ultimoAcceso' in progresion)) {
        progresion.ultimoAcceso = null;
        needsUpdate = true;
      }

      // Verificar si pasó medianoche y reiniciar contador
      const ahora = new Date();
      const ultimaActualizacion = progresion.ultimaActualizacionDiaria
        ? new Date(progresion.ultimaActualizacionDiaria)
        : null;

      if (ultimaActualizacion) {
        const medianoche = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
        const mediaNocheAnterior = new Date(
          ultimaActualizacion.getFullYear(),
          ultimaActualizacion.getMonth(),
          ultimaActualizacion.getDate()
        );

        // Si ya pasó medianoche, reiniciar contador
        if (medianoche > mediaNocheAnterior) {
          progresion.leccionesCompletadasHoy = 0;
          progresion.ultimaActualizacionDiaria = ahora.toISOString();
          needsUpdate = true;
          console.log('🔄 [getProgresion] Reiniciando contador diario (nueva fecha)');
        }
      }

      // Actualizar en BD si se agregaron campos o se reinició contador
      if (needsUpdate) {
        await progresionesCollection.updateOne(
          { usuarioID },
          {
            $set: {
              leccionesCompletadasHoy: progresion.leccionesCompletadasHoy,
              ultimaActualizacionDiaria: progresion.ultimaActualizacionDiaria,
              racha: progresion.racha,
              ultimoAcceso: progresion.ultimoAcceso,
            },
          }
        );
      }
    }

    res.status(200).json(progresion);
  } catch (error) {
    console.error('❌ Error obteniendo progresión:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/progresion/:usuarioID
router.put('/:usuarioID', async (req, res) => {
  try {
    const { usuarioID } = req.params;
    const { nivelActual, nivelesCompletados } = req.body;

    const db = getDB();
    const progresionesCollection = db.collection('Progresion');

    const updateDoc = {
      ultimaActividad: new Date().toISOString(),
    };

    if (nivelActual !== undefined) {
      updateDoc.nivelActual = nivelActual;
    }

    if (nivelesCompletados !== undefined) {
      updateDoc.nivelesCompletados = nivelesCompletados;
    }

    const result = await progresionesCollection.updateOne(
      { usuarioID },
      { $set: updateDoc }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Progresión no encontrada' });
    }

    res.status(200).json({ message: 'Progresión actualizada' });
  } catch (error) {
    console.error('❌ Error actualizando progresión:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/progresion/completar-nivel
router.post('/completar-nivel', async (req, res) => {
  try {
    const { usuarioID, nivel, resultado, experienciaGanada = 0 } = req.body;

    console.log(
      `📥 Completando nivel - Usuario: ${usuarioID}, Nivel: ${nivel}, Resultado: ${resultado}, Experiencia: ${experienciaGanada}`
    );

    const db = getDB();
    const progresionesCollection = db.collection('Progresion');

    const progresion = await progresionesCollection.findOne({ usuarioID });

    if (!progresion) {
      return res.status(404).json({ message: 'Progresión no encontrada' });
    }

    const nivelesCompletados = progresion.nivelesCompletados || [];

    // Acumular experiencia SIEMPRE (independientemente del resultado)
    const experienciaActual = progresion.experienciaTotal || 0;
    const nuevaExperiencia = experienciaActual + experienciaGanada;

    console.log(`💫 Acumulando experiencia: ${experienciaActual} + ${experienciaGanada} = ${nuevaExperiencia}`);

    // Verificar y reiniciar contador diario si es necesario
    const ahora = new Date();
    const ultimaActualizacion = progresion.ultimaActualizacionDiaria
      ? new Date(progresion.ultimaActualizacionDiaria)
      : null;

    let leccionesCompletadasHoy = progresion.leccionesCompletadasHoy || 0;
    let reiniciarContador = false;

    if (ultimaActualizacion) {
      const medianoche = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
      const mediaNocheAnterior = new Date(
        ultimaActualizacion.getFullYear(),
        ultimaActualizacion.getMonth(),
        ultimaActualizacion.getDate()
      );

      if (medianoche > mediaNocheAnterior) {
        reiniciarContador = true;
        leccionesCompletadasHoy = 0;
        console.log('🔄 Reiniciando contador diario (nueva fecha)');
      }
    }

    // Incrementar contador solo si es nivel real (no repaso)
    let metaDiariaCompletada = false;
    let bonusXP = 0;

    // Si es éxito y el nivel no está completado, agregarlo a nivelesCompletados
    if (resultado.toLowerCase() === 'exito' && !nivelesCompletados.includes(nivel)) {
      nivelesCompletados.push(nivel);

      // Incrementar contador diario solo para lecciones nuevas (nivel > 0)
      if (nivel > 0) {
        leccionesCompletadasHoy++;
        console.log(`📊 Progreso diario: ${leccionesCompletadasHoy}/5`);

        // Verificar si se completó la meta diaria (5 lecciones)
        if (leccionesCompletadasHoy === 5) {
          metaDiariaCompletada = true;
          bonusXP = 15;
          console.log('🎉 ¡Meta diaria completada! +15 XP bonus');
        }
      }

      // Calcular nivel basado en el total de lecciones completadas
      const nuevoNivelActual = nivelesCompletados.length;
      const experienciaFinal = nuevaExperiencia + bonusXP;

      await progresionesCollection.updateOne(
        { usuarioID },
        {
          $set: {
            nivelesCompletados,
            nivelActual: nuevoNivelActual,
            experienciaTotal: experienciaFinal,
            leccionesCompletadasHoy,
            ultimaActualizacionDiaria: ahora.toISOString(),
            ultimaActividad: new Date().toISOString(),
          },
        }
      );

      console.log(
        `✅ Nivel completado exitosamente - Total lecciones: ${nivelesCompletados.length}, Nivel: ${nuevoNivelActual}, Experiencia: ${experienciaFinal}`
      );
    } else {
      // Solo actualizar experiencia (sin marcar como completado)
      const updateDoc = {
        experienciaTotal: nuevaExperiencia,
        ultimaActividad: new Date().toISOString(),
      };

      // Si se reinició el contador, actualizar también
      if (reiniciarContador) {
        updateDoc.leccionesCompletadasHoy = 0;
        updateDoc.ultimaActualizacionDiaria = ahora.toISOString();
      }

      await progresionesCollection.updateOne({ usuarioID }, { $set: updateDoc });

      console.log(`📝 Experiencia acumulada sin completar nivel - Experiencia total: ${nuevaExperiencia}`);
    }

    res.status(200).json({
      message: 'Nivel completado',
      success: true,
      metaDiariaCompletada,
      bonusXP,
      leccionesCompletadasHoy,
    });
  } catch (error) {
    console.error('❌ Error completando nivel:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/progresion/registrar-intento
router.post('/registrar-intento', async (req, res) => {
  try {
    const { usuarioID, nivel, resultado } = req.body;

    console.log(`📥 Registrando intento - Usuario: ${usuarioID}, Nivel: ${nivel}, Resultado: ${resultado}`);

    const db = getDB();
    const progresionesCollection = db.collection('Progresion');

    const progresion = await progresionesCollection.findOne({ usuarioID });

    if (!progresion) {
      return res.status(404).json({ message: 'Progresión no encontrada' });
    }

    const estadisticas = progresion.estadisticas || {};
    const totalExitos = (estadisticas.totalExitos || 0);
    const totalFallos = (estadisticas.totalFallos || 0);
    const totalIntentos = (estadisticas.totalIntentos || 0);

    const nuevoExitos = resultado.toLowerCase() === 'exito' ? totalExitos + 1 : totalExitos;
    const nuevoFallos = resultado.toLowerCase() === 'fallo' ? totalFallos + 1 : totalFallos;

    await progresionesCollection.updateOne(
      { usuarioID },
      {
        $set: {
          'estadisticas.totalExitos': nuevoExitos,
          'estadisticas.totalFallos': nuevoFallos,
          'estadisticas.totalIntentos': totalIntentos + 1,
          ultimaActividad: new Date().toISOString(),
        },
      }
    );

    console.log('✅ Intento registrado exitosamente');

    res.status(200).json({ message: 'Intento registrado', success: true });
  } catch (error) {
    console.error('❌ Error registrando intento:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
