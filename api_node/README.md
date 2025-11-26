# API Inclusign - Node.js

API REST para la aplicación Inclusign (aprendizaje de lenguaje de señas).

## Características

- Node.js + Express
- MongoDB Atlas
- Sistema de autenticación con SHA-256
- Gestión de progresión de usuarios
- Sistema de rachas diarias
- CORS habilitado

## Instalación

```bash
npm install
```

## Configuración

Crear archivo `.env` con:

```
MONGODB_URI=mongodb+srv://usuario:contraseña@cluster.mongodb.net/
DATABASE_NAME=inclusign
PORT=5246
```

## Ejecución

```bash
# Desarrollo
npm start

# Producción
npm start
```

## Endpoints

### Autenticación
- `POST /api/auth/register` - Registrar nuevo usuario
- `POST /api/auth/login` - Iniciar sesión

### Progresión
- `GET /api/progresion/:usuarioID` - Obtener progresión del usuario
- `PUT /api/progresion/:usuarioID` - Actualizar progresión
- `POST /api/progresion/completar-nivel` - Completar nivel
- `POST /api/progresion/registrar-intento` - Registrar intento

### Usuarios
- `GET /api/usuarios/:usuarioID` - Obtener usuario por ID
- `GET /api/usuarios/by-email/:email` - Obtener usuario por email

### Niveles
- `GET /api/niveles` - Obtener todos los niveles
- `GET /api/niveles/:nivelID` - Obtener nivel específico

### Contenido
- `GET /api/abecedario` - Obtener metadata del abecedario
- `GET /api/gestos` - Obtener metadata de gestos

## Despliegue en Vercel

1. Instalar Vercel CLI: `npm i -g vercel`
2. Iniciar sesión: `vercel login`
3. Desplegar: `vercel`
4. Configurar variables de entorno en el dashboard de Vercel

## Despliegue en Railway

1. Conectar repositorio a Railway
2. Configurar variables de entorno en el dashboard
3. Railway detectará automáticamente el `package.json` y desplegará

## Estructura del proyecto

```
api_node/
├── src/
│   ├── config/
│   │   └── database.js       # Configuración MongoDB
│   ├── routes/
│   │   ├── auth.js           # Rutas de autenticación
│   │   ├── progresion.js     # Rutas de progresión
│   │   ├── usuarios.js       # Rutas de usuarios
│   │   ├── niveles.js        # Rutas de niveles
│   │   ├── abecedario.js     # Rutas de abecedario
│   │   └── gestos.js         # Rutas de gestos
│   └── utils/
│       └── auth.js           # Utilidades de autenticación
├── index.js                  # Punto de entrada
├── package.json
├── vercel.json              # Configuración Vercel
└── .env                     # Variables de entorno (no commiteado)
```

## Colecciones MongoDB

- **Usuarios**: Información de usuarios registrados
- **Progresion**: Progreso de cada usuario
- **Niveles**: Metadata de los niveles/lecciones
- **Abecedario**: Metadata del alfabeto (27 letras)
- **Gestos**: Metadata de gestos/frases (21 gestos)

**Nota**: Los GIFs se cargan desde assets locales en la app Flutter, no desde la API.
