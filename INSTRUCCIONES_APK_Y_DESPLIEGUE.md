# Instrucciones para Compartir APK y Desplegar API

## ✅ APK Generado

Tu APK está listo en:
```
C:\Users\ferna\OneDrive\Escritorio\Inclusign\inclusing_language_flutter\build\app\outputs\flutter-apk\app-release.apk
```

**Tamaño:** 123.8 MB

### Cómo compartir el APK:

1. **Opción 1 - USB/Bluetooth:**
   - Copia el archivo `app-release.apk` a tu teléfono
   - Instala directamente desde el archivo
   - Tus compañeros deben estar en la misma red WiFi (192.168.43.19) para que funcione

2. **Opción 2 - Google Drive/Dropbox:**
   - Sube el APK a Google Drive o Dropbox
   - Comparte el enlace con tus compañeros
   - Ellos lo descargan e instalan
   - ⚠️ Solo funcionará en la misma red WiFi que tu PC

3. **Opción 3 - Desplegar API primero (RECOMENDADO):**
   - Despliega la API en Vercel/Railway (ver instrucciones abajo)
   - Actualiza la URL en `constants.dart`
   - Regenera el APK con `flutter build apk --release`
   - Ahora el APK funcionará desde cualquier lugar con internet

---

## 🚀 Desplegar API en Vercel (GRATIS, RECOMENDADO)

### Paso 1: Crear cuenta en Vercel

1. Ve a https://vercel.com
2. Crea cuenta con GitHub (es gratis)

### Paso 2: Instalar Vercel CLI

```bash
npm install -g vercel
```

### Paso 3: Hacer login

```bash
vercel login
```

### Paso 4: Desplegar

```bash
cd C:\Users\ferna\OneDrive\Escritorio\Inclusign\api_node
vercel
```

Sigue las instrucciones:
- Set up and deploy? **Y**
- Which scope? Selecciona tu cuenta
- Link to existing project? **N**
- What's your project's name? **inclusign-api**
- In which directory is your code located? **./**
- Want to override the settings? **N**

### Paso 5: Configurar variables de entorno

Después del despliegue, ve a:
1. https://vercel.com/dashboard
2. Selecciona tu proyecto "inclusign-api"
3. Ve a Settings → Environment Variables
4. Agrega:
   - `MONGODB_URI` = `mongodb+srv://angel_artu:Test123456@includesign.zz0yofi.mongodb.net/?retryWrites=true&w=majority&appName=inclusign`
   - `DATABASE_NAME` = `inclusign`
   - `PORT` = `5246`

5. Redespliega: `vercel --prod`

### Paso 6: Obtener URL

Vercel te dará una URL como: `https://inclusign-api-xxxxx.vercel.app`

### Paso 7: Actualizar Flutter

Edita `inclusing_language_flutter/lib/utils/constants.dart`:

```dart
static const String baseUrl = 'https://inclusign-api-xxxxx.vercel.app/api';
```

### Paso 8: Regenerar APK

```bash
cd inclusing_language_flutter
flutter clean
flutter build apk --release
```

---

## 🚀 Desplegar API en Railway (ALTERNATIVA)

### Paso 1: Crear cuenta

1. Ve a https://railway.app
2. Crea cuenta con GitHub

### Paso 2: Crear nuevo proyecto

1. Click en "New Project"
2. Selecciona "Deploy from GitHub repo"
3. Conecta tu repositorio o sube el código manualmente

### Paso 3: Configurar variables de entorno

En el dashboard de Railway:
- `MONGODB_URI` = tu cadena de conexión MongoDB
- `DATABASE_NAME` = `inclusign`
- `PORT` = `5246`

### Paso 4: Desplegar

Railway detectará automáticamente que es Node.js y lo desplegará.

Obtendrás una URL como: `https://tu-app.up.railway.app`

---

## 📱 Pruebas Locales (Red Local)

Si tus compañeros están en la misma red WiFi que tú:

1. Asegúrate que tu PC tenga la API corriendo:
   ```bash
   cd C:\Users\ferna\OneDrive\Escritorio\Inclusign\api_node
   npm start
   ```

2. Verifica tu IP local:
   ```bash
   ipconfig
   ```
   Busca "IPv4 Address" en la red WiFi (ej: 192.168.43.19)

3. Comparte el APK actual (ya está configurado para 192.168.43.19)

4. ⚠️ Tu PC debe estar encendida con la API corriendo para que funcione

---

## 🎯 Resumen de Opciones

| Opción | Ventajas | Desventajas |
|--------|----------|-------------|
| **Red Local** | No requiere despliegue | Solo funciona en tu red WiFi, PC debe estar encendida |
| **Vercel** | Gratis, fácil de usar, funciona desde cualquier lugar | Límites de uso gratuito |
| **Railway** | Gratis al inicio, más flexible | Más complejo de configurar |

---

## 📝 Notas Importantes

1. **Tamaño del APK:** 123.8 MB es grande por los GIFs incluidos. Esto es normal.

2. **Instalación en Android:**
   - Los usuarios deben habilitar "Instalar apps de origen desconocido"
   - En Android 8+: Configuración → Seguridad → Orígenes desconocidos

3. **Primera ejecución:**
   - La app puede tardar unos segundos en cargar por los GIFs

4. **Conexión a MongoDB:**
   - La API conecta directamente a tu MongoDB Atlas
   - Asegúrate de que la IP de Vercel/Railway esté permitida en MongoDB Atlas
   - MongoDB Atlas → Network Access → Add IP Address → Allow Access from Anywhere (0.0.0.0/0)

---

## ✅ Checklist Final

Antes de compartir el APK:

- [ ] API desplegada en Vercel/Railway (o PC corriendo la API local)
- [ ] URL actualizada en `constants.dart`
- [ ] APK regenerado con `flutter build apk --release`
- [ ] Probado el APK en al menos un dispositivo
- [ ] MongoDB Atlas permite conexiones desde la IP de Vercel/Railway
- [ ] Compañeros tienen Android 7.0 o superior

---

## 🆘 Solución de Problemas

### Error: "No se puede conectar al servidor"
- Verifica que la API esté corriendo
- Revisa la URL en `constants.dart`
- Chequea que MongoDB Atlas permite conexiones

### Error: "Instalación bloqueada"
- Habilita instalación de apps de origen desconocido
- Settings → Security → Unknown sources

### La app se cierra inmediatamente
- Verifica que los GIFs estén en `assets/gifs/`
- Regenera el APK con `flutter clean && flutter build apk --release`

---

## 📧 Contacto

Si tienes problemas, revisa los logs:
- API Node.js: En la consola donde está corriendo `npm start`
- Flutter: `flutter run` en modo debug muestra errores detallados
