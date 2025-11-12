# 📁 Assets de GIFs - Instrucciones

Esta carpeta contiene todos los GIFs del alfabeto y gestos que se usan en la aplicación.

## 📂 Estructura de Carpetas

```
assets/gifs/
├── abecedario/     # GIFs de las letras A-Z y Ñ (27 archivos)
│   ├── A.gif
│   ├── B.gif
│   ├── C.gif
│   └── ...
└── gestos/         # GIFs de los gestos básicos (21 archivos)
    ├── HOLA.gif
    ├── BUENOS_DIAS.gif
    ├── PORFAVOR.gif
    └── ...
```

## 🔤 Abecedario (27 archivos)

Guarda los GIFs con el nombre de la letra **EN MAYÚSCULA**:

```
A.gif       G.gif       M.gif       S.gif       Y.gif
B.gif       H.gif       N.gif       T.gif       Z.gif
C.gif       I.gif       Ñ.gif       U.gif
D.gif       J.gif       O.gif       V.gif
E.gif       K.gif       P.gif       W.gif
F.gif       L.gif       Q.gif       X.gif
            R.gif
```

## 🎭 Gestos (21 archivos)

Guarda los GIFs con los nombres **EN MAYÚSCULAS y CON GUIONES BAJOS** (en lugar de espacios):

```
HOLA.gif
BUENOS_DIAS.gif
PORFAVOR.gif
GRACIAS.gif
BUENAS_NOCHES.gif
COMO_ESTAS.gif
SI.gif
NO.gif
PUEDO_AYUDARTE.gif
HOLA_GUSTO_CONOCERTE.gif
CUAL_ES_TU_NOMBRE.gif
MI_NOMBRE_ES.gif
ENTIENDO.gif
NO_ENTIENDO.gif
OYENTE.gif
SORDO.gif
ERES_SORDO.gif
PODEMOS_HABLAR.gif
POR_QUE.gif
QUIEN.gif
CUIDATE_MUCHO.gif
```

## 📥 Cómo Exportar desde MongoDB

### Opción 1: Script de Exportación (Recomendado)

Crea un script para descargar todos los GIFs desde MongoDB:

```bash
# Ver script en: INSTRUCCIONES_EXPORTAR.md
```

### Opción 2: Manualmente desde MongoDB Compass

1. Abre MongoDB Compass
2. Conecta a tu base de datos `inclusign`
3. Ve a la colección `Abecedario` o `Gestos`
4. Para cada documento:
   - Copia el campo `contenido` (base64)
   - Decodifica el base64 a archivo
   - Guarda con el nombre correcto en la carpeta correspondiente

## ✅ Verificación

Después de copiar todos los GIFs, verifica que tengas:

- ✅ 27 archivos en `assets/gifs/abecedario/`
- ✅ 21 archivos en `assets/gifs/gestos/`
- ✅ Total: 48 archivos .gif

## 🚀 Ventajas de Usar Assets Locales

- ⚡ **Carga instantánea**: No depende de la red
- 🔒 **Sin errores de conexión**: Funciona sin internet
- 📦 **Incluido en la app**: Los GIFs se empaquetan con la aplicación
- 💾 **Sin caché complejo**: Flutter maneja automáticamente los assets

## 🔧 Después de Agregar los GIFs

1. Asegúrate de que todos los archivos estén en las carpetas correctas
2. Ejecuta: `flutter pub get`
3. Limpia el build: `flutter clean`
4. Ejecuta la app: `flutter run`

Los GIFs se cargarán automáticamente cuando el usuario navegue a cada lección.
