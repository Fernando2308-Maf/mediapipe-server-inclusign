# Guía de Despliegue en Vercel - API Inclusign

Esta guía te llevará paso a paso para desplegar tu API de Node.js en Vercel.

## Requisitos previos

1. Cuenta de GitHub (donde está tu código)
2. Conexión a MongoDB Atlas configurada

---

## Paso 1: Crear cuenta en Vercel

1. Ve a [vercel.com](https://vercel.com/)
2. Haz clic en **"Sign Up"**
3. Selecciona **"Continue with GitHub"**
4. Autoriza a Vercel para acceder a tu cuenta de GitHub

---

## Paso 2: Importar tu proyecto

1. En el dashboard de Vercel, haz clic en **"Add New..."** → **"Project"**
2. Busca tu repositorio de **Inclusign** en la lista
3. Haz clic en **"Import"** junto al nombre del repositorio

---

## Paso 3: Configurar el proyecto

En la pantalla de configuración del proyecto:

### A) Configuración general:

- **Project Name**: `inclusign-api` (o el nombre que prefieras)
- **Framework Preset**: Vercel lo detectará automáticamente como "Other"
- **Root Directory**: Haz clic en **"Edit"** y escribe `api_node`
  - Esto es MUY importante porque tu API está en la carpeta `api_node`

### B) Environment Variables (Variables de entorno):

Haz clic en la sección **"Environment Variables"** y agrega las siguientes:

1. **Primera variable**:
   - **Name**: `MONGODB_URI`
   - **Value**: Tu URI de MongoDB Atlas (ejemplo: `mongodb+srv://usuario:contraseña@cluster.mongodb.net/`)
   - Marca: **Production**, **Preview**, y **Development**

2. **Segunda variable**:
   - **Name**: `DATABASE_NAME`
   - **Value**: `inclusign`
   - Marca: **Production**, **Preview**, y **Development**

### ¿Dónde obtener tu MONGODB_URI?

1. Ve a [cloud.mongodb.com](https://cloud.mongodb.com/)
2. Inicia sesión en tu cuenta de MongoDB Atlas
3. Haz clic en **"Connect"** en tu cluster
4. Selecciona **"Connect your application"**
5. Copia la URI de conexión (se verá como: `mongodb+srv://...`)
6. Reemplaza `<password>` con tu contraseña real de MongoDB

---

## Paso 4: Desplegar

1. Una vez configurado todo, haz clic en **"Deploy"**
2. Vercel comenzará a compilar y desplegar tu API
3. Este proceso toma aproximadamente **1-2 minutos**
4. Verás un mensaje de progreso que dice "Building..."

---

## Paso 5: Verificar el despliegue

1. Cuando termine, verás un mensaje de **"Congratulations!"** 🎉
2. Haz clic en **"Visit"** o copia la URL que se muestra
3. La URL será algo como: `https://inclusign-api.vercel.app` o `https://inclusign-api-tunombre.vercel.app`
4. Al abrir esa URL en tu navegador, deberías ver:

```json
{
  "message": "✅ API Inclusign funcionando correctamente",
  "version": "1.0.0",
  "endpoints": {
    "auth": "/api/auth",
    "progresion": "/api/progresion",
    ...
  }
}
```

---

## Paso 6: Probar los endpoints

Prueba que la API funcione correctamente:

### Probar desde el navegador:
- Abre: `https://tu-proyecto.vercel.app/api/niveles`
- Deberías ver la lista de niveles en formato JSON

### Probar el login (usando curl o Postman):
```bash
curl -X POST "https://tu-proyecto.vercel.app/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## Paso 7: Actualizar la app Flutter

Ahora necesitas actualizar tu app Flutter para que use la nueva URL de Vercel:

1. Abre el archivo:
   ```
   inclusing_language_flutter/lib/utils/constants.dart
   ```

2. En la **línea 13**, cambia la URL a tu URL de Vercel:
   ```dart
   static const String baseUrl = 'https://tu-proyecto.vercel.app/api';
   ```

3. Asegúrate de agregar `/api` al final de la URL

4. Guarda el archivo

---

## Paso 8: Recompilar el APK

Ahora compila el APK con la nueva URL de producción:

```bash
cd inclusing_language_flutter
flutter build apk --release
```

El APK estará en:
```
inclusing_language_flutter\build\app\outputs\flutter-apk\app-release.apk
```

---

## Paso 9: Compartir el APK con tus amigos

1. Copia el archivo `app-release.apk` a tu celular o compártelo vía WhatsApp/Drive
2. Tus amigos deben:
   - Habilitar "Instalar aplicaciones de fuentes desconocidas" en su celular
   - Descargar el APK
   - Instalarlo
   - Podrán registrarse y crear su cuenta

---

## Configuración adicional de Vercel (Opcional)

### Agregar un dominio personalizado:

1. En el dashboard de Vercel, ve a tu proyecto
2. Haz clic en **"Settings"** → **"Domains"**
3. Agrega tu dominio personalizado si tienes uno

### Ver los logs:

1. En el dashboard, haz clic en tu proyecto
2. Ve a la pestaña **"Deployments"**
3. Haz clic en el despliegue más reciente
4. Haz clic en **"View Function Logs"** para ver los registros

---

## Redesplegar después de hacer cambios

Cada vez que hagas cambios en tu código y los subas a GitHub:

1. Haz commit de tus cambios:
   ```bash
   git add .
   git commit -m "Actualizar API"
   git push
   ```

2. Vercel automáticamente detectará los cambios y redesplegará tu API
3. No necesitas hacer nada más, es automático

---

## Solución de problemas

### Error: "Cannot connect to MongoDB"

**Causa**: IP no autorizada en MongoDB Atlas

**Solución**:
1. Ve a MongoDB Atlas
2. Haz clic en **"Network Access"** en el menú lateral
3. Haz clic en **"Add IP Address"**
4. Selecciona **"Allow Access from Anywhere"** (0.0.0.0/0)
5. Haz clic en **"Confirm"**

### Error 404 al hacer peticiones

**Causa**: URL incorrecta en Flutter

**Solución**: Asegúrate de que la URL en `constants.dart` termine con `/api`:
```dart
static const String baseUrl = 'https://tu-proyecto.vercel.app/api';
```

### El despliegue falla

**Causa**: Configuración incorrecta del Root Directory

**Solución**:
1. Ve a tu proyecto en Vercel
2. Haz clic en **"Settings"**
3. Busca **"Root Directory"**
4. Asegúrate de que diga `api_node`
5. Guarda y vuelve a desplegar

### Variables de entorno no funcionan

**Solución**:
1. Ve a **"Settings"** → **"Environment Variables"**
2. Verifica que `MONGODB_URI` y `DATABASE_NAME` estén correctas
3. Asegúrate de marcar las 3 opciones: Production, Preview, Development
4. Después de editar, haz clic en **"Redeploy"** en la pestaña Deployments

---

## Verificar que todo funcione

Checklist final:

- [ ] La URL de Vercel muestra el mensaje de bienvenida de la API
- [ ] El endpoint `/api/niveles` devuelve datos
- [ ] MongoDB Atlas permite conexiones desde 0.0.0.0/0
- [ ] El archivo `constants.dart` tiene la URL correcta de Vercel
- [ ] El APK fue recompilado después de cambiar la URL
- [ ] La app puede registrar nuevos usuarios
- [ ] La app puede hacer login con usuarios existentes

---

## Limitaciones de Vercel (Plan gratuito)

- **Tiempo de ejecución**: Máximo 10 segundos por petición (suficiente para tu API)
- **Tamaño de respuesta**: Máximo 4.5 MB (suficiente para tus GIFs en base64)
- **Despliegues**: Ilimitados
- **Banda ancha**: 100 GB/mes (suficiente para cientos de usuarios)

---

## URLs importantes

- **Dashboard de Vercel**: [vercel.com/dashboard](https://vercel.com/dashboard)
- **MongoDB Atlas**: [cloud.mongodb.com](https://cloud.mongodb.com/)
- **Documentación de Vercel**: [vercel.com/docs](https://vercel.com/docs)

---

## Siguiente paso

Una vez desplegado, comparte el APK con tus amigos y pídeles que prueben:
1. Registrarse con un nuevo usuario
2. Iniciar sesión
3. Completar una lección
4. Verificar que el progreso se guarde correctamente

---

¡Listo! Tu API ahora está en producción y accesible desde cualquier lugar del mundo. 🚀
