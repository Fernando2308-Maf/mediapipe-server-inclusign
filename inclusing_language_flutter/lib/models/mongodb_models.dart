// Modelos para las colecciones de MongoDB

/// Colección: Usuarios
class Usuario {
  final String? id; // _id de MongoDB
  final String usuarioID;
  final String nombre;
  final String correo;
  final String pass;
  final String fechaRegistro;

  Usuario({
    this.id,
    required this.usuarioID,
    required this.nombre,
    required this.correo,
    required this.pass,
    required this.fechaRegistro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id']?.toString(),
      usuarioID: json['usuarioID'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      pass: json['pass'] ?? '',
      fechaRegistro: json['fechaRegistro'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'usuarioID': usuarioID,
      'nombre': nombre,
      'correo': correo,
      'pass': pass,
      'fechaRegistro': fechaRegistro,
    };
  }
}

/// Colección: Progresion
class Progresion {
  final String? id; // _id de MongoDB
  final String usuarioID;
  final int nivelActual;
  final List<int> nivelesCompletados;
  final List<Intento> intentos;
  final Estadisticas estadisticas;
  final int experienciaTotal;
  final int leccionesCompletadasHoy;
  final DateTime? ultimaActualizacionDiaria;

  Progresion({
    this.id,
    required this.usuarioID,
    required this.nivelActual,
    required this.nivelesCompletados,
    required this.intentos,
    required this.estadisticas,
    this.experienciaTotal = 0,
    this.leccionesCompletadasHoy = 0,
    this.ultimaActualizacionDiaria,
  });

  factory Progresion.fromJson(Map<String, dynamic> json) {
    return Progresion(
      id: json['_id']?.toString(),
      usuarioID: json['usuarioID'] ?? '',
      nivelActual: json['nivelActual'] ?? 1,
      nivelesCompletados: json['nivelesCompletados'] != null
          ? List<int>.from(json['nivelesCompletados'])
          : [],
      intentos: json['intentos'] != null
          ? (json['intentos'] as List).map((i) => Intento.fromJson(i)).toList()
          : [],
      estadisticas: json['estadisticas'] != null
          ? Estadisticas.fromJson(json['estadisticas'])
          : Estadisticas(tiempoJugadoMin: 0, totalIntentos: 0, totalExitos: 0),
      experienciaTotal: json['experienciaTotal'] ?? 0,
      leccionesCompletadasHoy: json['leccionesCompletadasHoy'] ?? 0,
      ultimaActualizacionDiaria: json['ultimaActualizacionDiaria'] != null
          ? DateTime.parse(json['ultimaActualizacionDiaria'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'usuarioID': usuarioID,
      'nivelActual': nivelActual,
      'nivelesCompletados': nivelesCompletados,
      'intentos': intentos.map((i) => i.toJson()).toList(),
      'estadisticas': estadisticas.toJson(),
      'experienciaTotal': experienciaTotal,
      'leccionesCompletadasHoy': leccionesCompletadasHoy,
      if (ultimaActualizacionDiaria != null)
        'ultimaActualizacionDiaria': ultimaActualizacionDiaria!.toIso8601String(),
    };
  }
}

class Intento {
  final int nivel;
  final String resultado; // "exito" o "fallo"
  final String fecha;

  Intento({
    required this.nivel,
    required this.resultado,
    required this.fecha,
  });

  factory Intento.fromJson(Map<String, dynamic> json) {
    return Intento(
      nivel: json['nivel'] ?? 0,
      resultado: json['resultado'] ?? '',
      fecha: json['fecha'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nivel': nivel,
      'resultado': resultado,
      'fecha': fecha,
    };
  }
}

class Estadisticas {
  final int tiempoJugadoMin;
  final int totalIntentos;
  final int totalExitos;

  Estadisticas({
    required this.tiempoJugadoMin,
    required this.totalIntentos,
    required this.totalExitos,
  });

  factory Estadisticas.fromJson(Map<String, dynamic> json) {
    return Estadisticas(
      tiempoJugadoMin: json['tiempoJugadoMin'] ?? 0,
      totalIntentos: json['totalIntentos'] ?? 0,
      totalExitos: json['totalExitos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tiempoJugadoMin': tiempoJugadoMin,
      'totalIntentos': totalIntentos,
      'totalExitos': totalExitos,
    };
  }
}

/// Colección: Niveles
class Nivel {
  final String? id; // _id de MongoDB
  final int nivelID;
  final String nombre;
  final int maxIntentos;
  final Recompensa recompensa;

  Nivel({
    this.id,
    required this.nivelID,
    required this.nombre,
    required this.maxIntentos,
    required this.recompensa,
  });

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      id: json['_id']?.toString(),
      nivelID: json['nivelID'] ?? 0,
      nombre: json['nombre'] ?? '',
      maxIntentos: json['maxIntentos'] ?? 10,
      recompensa: json['recompensa'] != null
          ? Recompensa.fromJson(json['recompensa'])
          : Recompensa(puntos: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nivelID': nivelID,
      'nombre': nombre,
      'maxIntentos': maxIntentos,
      'recompensa': recompensa.toJson(),
    };
  }
}

class Recompensa {
  final int puntos;

  Recompensa({required this.puntos});

  factory Recompensa.fromJson(Map<String, dynamic> json) {
    return Recompensa(
      puntos: json['puntos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puntos': puntos,
    };
  }
}
