# Guía de Despliegue - API Node.js de Inclusign

Esta guía te mostrará cómo desplegar tu API de Node.js en Railway (recomendado) o Render.

## Opción 1: Railway (RECOMENDADO - Más fácil)

Railway es la opción más sencilla y detecta automáticamente tu configuración.

### Paso 1: Crear cuenta en Railway

1. Ve a [railway.app](https://railway.app/)
2. Haz clic en "Start a New Project"
3. Inicia sesión con GitHub

### Paso 2: Crear nuevo proyecto

1. Haz clic en "New Project"
2. Selecciona "Deploy from GitHub repo"
3. Conecta tu cuenta de GitHub si aún no lo has hecho
4. Selecciona el repositorio de Inclusign
5. Railway detectará automáticamente que es un proyecto Node.js

### Paso 3: Configurar variables de entorno

1. En el dashboard de Railway, haz clic en tu servicio
2. Ve a la pestaña "Variables"
3. Agrega las siguientes variables:
   - `MONGODB_URI`: Tu URI de conexión a MongoDB Atlas
   - `DATABASE_NAME`: `inclusign`
   - `PORT`: Railway lo asignará automáticamente, pero puedes dejarlo en `5246`

4. Para obtener tu MONGODB_URI:
   - Ve a [cloud.mongodb.com](https://cloud.mongodb.com/)
   - Haz clic en "Connect" en tu cluster
   - Selecciona "Connect your application"
   - Copia la URI (se verá como: `mongodb+srv://usuario:contraseña@cluster.mongodb.net/`)

### Paso 4: Configurar el directorio raíz

1. En Railway, ve a "Settings"
2. Busca "Root Directory"
3. Establécelo en: `api_node`
4. Guarda los cambios

### Paso 5: Desplegar

1. Railway desplegará automáticamente tu API
2. Espera a que el despliegue termine (verás "Deploy successful")
3. Haz clic en "Settings" → "Domains"
4. Haz clic en "Generate Domain"
5. Copia la URL generada (será algo como: `https://tu-proyecto.up.railway.app`)

### Paso 6: Verificar el despliegue

1. Abre tu navegador
2. Ve a la URL que copiaste
3. Deberías ver el mensaje: "✅ API Inclusign funcionando correctamente"

### Paso 7: Actualizar la app Flutter

1. Abre el archivo `inclusing_language_flutter/lib/utils/constants.dart`
2. Cambia la línea 13 a tu nueva URL de Railway:
   ```dart
   static const String baseUrl = 'https://tu-proyecto.up.railway.app/api';
   ```
3. Recompila el APK:
   ```bash
   cd inclusing_language_flutter
   flutter build apk --release
   ```

---

## Opción 2: Render (Alternativa gratuita)

Render es otra opción gratuita con configuración manual.

### Paso 1: Crear cuenta en Render

1. Ve a [render.com](https://render.com/)
2. Haz clic en "Get Started for Free"
3. Inicia sesión con GitHub

### Paso 2: Crear nuevo Web Service

1. En el dashboard, haz clic en "New +"
2. Selecciona "Web Service"
3. Conecta tu repositorio de GitHub
4. Selecciona el repositorio de Inclusign

### Paso 3: Configurar el servicio

1. **Name**: `inclusign-api` (o el nombre que prefieras)
2. **Region**: Selecciona la más cercana a ti
3. **Branch**: `master` o `main`
4. **Root Directory**: `api_node`
5. **Runtime**: `Node`
6. **Build Command**: `npm install`
7. **Start Command**: `npm start`
8. **Plan**: Selecciona "Free"

### Paso 4: Configurar variables de entorno

1. En la sección "Environment Variables", haz clic en "Add Environment Variable"
2. Agrega las siguientes variables:
   - `MONGODB_URI`: Tu URI de MongoDB Atlas
   - `DATABASE_NAME`: `inclusign`
   - `PORT`: `10000` (Render usa este puerto por defecto)

### Paso 5: Desplegar

1. Haz clic en "Create Web Service"
2. Render comenzará a desplegar tu API (toma 5-10 minutos)
3. Espera a que el estado cambie a "Live"
4. Copia la URL (será algo como: `https://inclusign-api.onrender.com`)

### Paso 6: Verificar y actualizar Flutter

Sigue los mismos pasos que en Railway (Paso 6 y 7)

---

## Opción 3: Vercel (Ya está configurado)

Tu proyecto ya tiene un archivo `vercel.json`, así que también puedes desplegarlo en Vercel:

### Pasos rápidos:

1. Ve a [vercel.com](https://vercel.com/)
2. Inicia sesión con GitHub
3. Haz clic en "Add New..." → "Project"
4. Importa tu repositorio de Inclusign
5. Establece "Root Directory" en `api_node`
6. Agrega las variables de entorno (MONGODB_URI, DATABASE_NAME)
7. Haz clic en "Deploy"

**Nota**: Vercel tiene limitaciones para APIs que reciben muchas peticiones en el plan gratuito.

---

## Solución de Problemas

### Error: "Cannot connect to MongoDB"

- Verifica que tu URI de MongoDB sea correcta
- Asegúrate de que tu IP esté en la lista blanca de MongoDB Atlas:
  1. Ve a MongoDB Atlas
  2. Haz clic en "Network Access"
  3. Agrega `0.0.0.0/0` para permitir todas las IPs (solo para desarrollo)

### Error: "Port already in use"

- No te preocupes, los servicios cloud asignan el puerto automáticamente

### Error 404 al hacer peticiones

- Verifica que la URL en tu app Flutter incluya `/api` al final:
  ```dart
  static const String baseUrl = 'https://tu-proyecto.up.railway.app/api';
  ```

### El despliegue falla

- Verifica que el archivo `package.json` esté en `api_node/`
- Asegúrate de que `node_modules` esté en `.gitignore`
- Revisa los logs de despliegue en Railway/Render

---

## Comandos útiles para pruebas locales

Antes de desplegar, puedes probar localmente:

```bash
cd api_node
npm install
npm start
```

La API estará disponible en `http://localhost:5246`

---

## Próximos pasos después del despliegue

1. Recompila el APK con la nueva URL de producción
2. Comparte el APK con tus amigos
3. Prueba el registro y login desde la app
4. Monitorea los logs en Railway/Render para detectar errores

---

## Costos

- **Railway**: Gratis hasta $5/mes de uso
- **Render**: Gratis (con limitaciones de 512MB RAM)
- **Vercel**: Gratis (limitado para APIs)

**Recomendación**: Usa Railway para mejor rendimiento y facilidad de uso.
