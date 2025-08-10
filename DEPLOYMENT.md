# 🚀 SoundScape API - Guía de Deployment en Render

Esta guía te ayudará a deployar la API de SoundScape en Render.com

## 📋 Prerrequisitos

1. **Cuenta en Render.com** - Crea una cuenta gratuita en [render.com](https://render.com)
2. **Repositorio en GitHub** - Tu código debe estar en GitHub
3. **Variables de entorno** - Tendrás que configurar varias variables secretas

## 🗄️ Base de Datos PostgreSQL

### Paso 1: Crear la Base de Datos
1. En el dashboard de Render, haz clic en **"New +"** → **"PostgreSQL"**
2. Configura:
   - **Name**: `soundscape-postgres`
   - **Database**: `soundscape_production`
   - **User**: `soundscape`
   - **Plan**: Free (512 MB)
3. Haz clic en **"Create Database"**
4. Guarda la **Database URL** que se genera

## 🌐 API Web Service

### Paso 2: Crear el Web Service
1. En el dashboard de Render, haz clic en **"New +"** → **"Web Service"**
2. Conecta tu repositorio de GitHub
3. Configura:
   - **Name**: `soundscape-api`
   - **Runtime**: Docker
   - **Plan**: Free
   - **Build Command**: Dejarlo vacío (se usa Docker)
   - **Start Command**: Dejarlo vacío (se usa Docker)

### Paso 3: Configurar Variables de Entorno

En la sección **Environment Variables**, agrega:

#### Variables Automáticas (Render las proporciona)
- `DATABASE_URL` → Seleccionar desde la base de datos creada

#### Variables Requeridas (las tienes que configurar)
- `RAILS_MASTER_KEY` → Copia el contenido de `config/master.key`
- `OPENAI_API_KEY` → Tu clave API de OpenAI
- `SMTP_USERNAME` → Tu email de Gmail
- `SMTP_PASSWORD` → Tu contraseña de aplicación de Gmail
- `CORS_ALLOWED_ORIGINS` → URL de tu frontend en Vercel (ej: `https://soundscape-frontend.vercel.app`)

#### Variables con Valores por Defecto
```
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=enabled
RAILS_LOG_TO_STDOUT=enabled
SECRET_KEY_BASE=[Se genera automáticamente]
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=soundscape.onrender.com
```

### Paso 4: Deploy Automático
Una vez configurado, Render automáticamente:
1. Detectará el `render.yaml` en tu repositorio
2. Construirá la imagen Docker
3. Ejecutará las migraciones de base de datos
4. Iniciará el servidor

## 📧 Configuración de Email (Gmail)

### Obtener Contraseña de Aplicación Gmail
1. Ve a tu [Cuenta de Google](https://myaccount.google.com/)
2. Seguridad → Verificación en 2 pasos (debe estar activada)
3. Contraseñas de aplicaciones → Generar nueva
4. Selecciona "Correo" y "Otro dispositivo personalizado"
5. Usa esta contraseña en `SMTP_PASSWORD`

## 🌐 URLs y Endpoints

Una vez deployado, tu API estará disponible en:
```
https://soundscape-api.onrender.com
```

### Endpoints principales:
- Chequeo de salud: `GET /up`
- API base: `/api/v1/`
- Autenticación: `/api/v1/auth/login`
- Playlists: `/api/v1/playlists`
- Búsqueda con IA: `/api/v1/ai_search`

## 🔧 Solución de Problemas

### Error: "El servicio web no pudo iniciar"
1. Revisa los logs en Render Dashboard
2. Verifica que `RAILS_MASTER_KEY` sea correcto
3. Asegúrate de que todas las variables de entorno estén configuradas

### Error: Conexión a la base de datos
1. Verifica que `DATABASE_URL` esté conectada correctamente
2. La base de datos debe estar en el mismo proyecto

### Error: CORS
1. Verifica que `CORS_ALLOWED_ORIGINS` contenga la URL exacta de tu frontend
2. No agregues "/" al final de las URLs

### Error: Envío de correo
1. Verifica `SMTP_USERNAME` y `SMTP_PASSWORD`
2. Asegúrate de usar una contraseña de aplicación, no tu contraseña de Gmail normal

## 📱 Próximo Paso: Frontend en Vercel

Una vez que tu API esté funcionando:
1. Anota la URL de tu API: `https://soundscape-api.onrender.com`
2. Ve al directorio del frontend para deployar en Vercel
3. Configura `NEXT_PUBLIC_API_URL` con tu URL de API

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs en Render Dashboard
2. Verifica que todas las variables de entorno estén configuradas
3. Prueba los endpoints manualmente con curl o Postman
