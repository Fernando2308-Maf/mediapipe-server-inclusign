const crypto = require('crypto');

// Generar usuarioID único
function generateUsuarioID() {
  const ticks = Date.now();
  return `u${ticks}`;
}

// Hash de contraseña usando SHA-256 (mismo que Dart)
function hashPassword(password) {
  const hash = crypto.createHash('sha256');
  hash.update(password);
  return hash.digest('base64');
}

// Verificar contraseña
function verifyPassword(password, hash) {
  return hashPassword(password) === hash;
}

// Generar token simple (mismo que Dart)
function generateToken(usuarioID) {
  const data = `${usuarioID}:${Date.now()}`;
  return Buffer.from(data).toString('base64');
}

module.exports = {
  generateUsuarioID,
  hashPassword,
  verifyPassword,
  generateToken,
};
