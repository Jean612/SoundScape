# SoundScape API

SoundScape es una API REST construida con Ruby on Rails que permite a los usuarios gestionar listas de reproducción de música con autenticación segura, búsqueda inteligente con IA y exportación a plataformas como Spotify y YouTube Music.

## 🎵 Características Principales

- **Autenticación JWT** con confirmación de email obligatoria
- **Gestión de Playlists** y canciones con autorización basada en roles
- **Búsqueda Inteligente con IA** usando Google Gemini para sugerencias de canciones
- **Sistema de Analytics** para tracking de búsquedas y tendencias
- **Cache Inteligente** y rate limiting para optimización de rendimiento
- **Exportación** a Spotify/YouTube Music (próximamente)

## 🛠 Tecnologías

- **Ruby** 3.2.2
- **Rails** 8.0 (API mode)
- **PostgreSQL** como base de datos
- **JWT** para autenticación
- **CanCanCan** para autorización
- **Google Gemini AI** para búsqueda inteligente
- **RSpec** para testing
- **RuboCop** para formateo de código

## 📋 Requisitos del Sistema

- Ruby 3.2.2+
- PostgreSQL 12+
- Redis (para cache y rate limiting)
- Gemini API Key de Google

## ⚙️ Configuración

### 1. Instalación

```bash
# Clonar el repositorio
git clone <repository-url>
cd SoundScape

# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create
rails db:migrate
```

### 2. Variables de Entorno

Crear archivo `.env` basado en `.env.example`:

```bash
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost/soundscape_development

# Email Configuration  
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_DOMAIN=soundscape.com

# AI Configuration
GEMINI_API_KEY=your-gemini-api-key-here

# Redis Configuration (for caching and rate limiting)
REDIS_URL=redis://localhost:6379/0
```

### 3. Obtener Gemini API Key

1. Visita [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Crea una nueva API key
3. Agrega la key a tu archivo `.env`

## 🚀 Uso

### Iniciar el servidor

```bash
rails server
```

### Endpoints principales

#### Autenticación

```bash
# Registro
POST /api/v1/auth/register
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "name": "Usuario",
    "username": "usuario123",
    "birth_date": "1990-01-01",
    "country": "España"
  }
}

# Login (requiere email confirmado)
POST /api/v1/auth/login
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}

# Confirmar email
GET /api/v1/auth/confirm_email?token=CONFIRMATION_TOKEN
```

#### Búsqueda con IA

```bash
# Buscar canciones con IA
POST /api/v1/ai_search
Authorization: Bearer JWT_TOKEN
{
  "query": "Beatles love songs",
  "limit": 5
}

# Obtener búsquedas trending
GET /api/v1/ai_search/trending?limit=10&time_period=24

# Historial de búsquedas del usuario
GET /api/v1/ai_search/history?page=1&per_page=20
```

#### Gestión de Playlists

```bash
# Crear playlist
POST /api/v1/playlists
Authorization: Bearer JWT_TOKEN
{
  "playlist": {
    "name": "Mi Playlist",
    "description": "Descripción opcional"
  }
}

# Listar playlists del usuario
GET /api/v1/playlists
Authorization: Bearer JWT_TOKEN

# Agregar canción a playlist
POST /api/v1/playlists/:playlist_id/songs
Authorization: Bearer JWT_TOKEN
{
  "playlist_song": {
    "song_id": 1
  }
}
```

## 🧪 Testing

```bash
# Ejecutar todos los tests
rspec

# Ejecutar tests específicos
rspec spec/models/
rspec spec/controllers/
rspec spec/services/

# Con detalles de cobertura
rspec --format documentation
```

Actualmente tenemos **107+ tests pasando** con cobertura completa de:
- Modelos y validaciones
- Controladores y autenticación
- Servicios de IA y cache
- Analytics y rate limiting

## 📊 Funcionalidades de IA

### Búsqueda Inteligente

El sistema utiliza **Google Gemini 1.5 Flash** para generar sugerencias inteligentes de canciones:

- **Cache**: Resultados cacheados por 1 hora para mejor rendimiento
- **Rate Limiting**: 60 búsquedas por hora por usuario
- **Validación**: Queries entre 2-100 caracteres
- **Fallback**: Respuesta graceful cuando la IA no está disponible

### Analytics y Tendencias

- **Tracking de búsquedas**: Registra consultas, timestamps y resultados
- **Búsquedas trending**: Top consultas en períodos configurables
- **Historial personal**: Búsquedas paginadas por usuario
- **Datos anónimos**: IP addresses para analytics sin identificación personal

## 🔒 Seguridad

- **JWT Authentication** con tokens seguros
- **Email confirmation** obligatoria antes del acceso
- **Rate limiting** por usuario y endpoint
- **Authorization** basada en roles con CanCanCan
- **Validación** exhaustiva de inputs
- **Logs seguros** sin exposición de datos sensibles

## 🚀 Deployment

### Producción

1. Configurar variables de entorno en el servidor
2. Ejecutar migraciones: `rails db:migrate RAILS_ENV=production`
3. Compilar assets: `rails assets:precompile RAILS_ENV=production`
4. Iniciar servidor: `rails server -e production`

### Docker (próximamente)

```bash
docker-compose up -d
```

## 📈 Roadmap

- [ ] Integración con Spotify API
- [ ] Integración con YouTube Music API
- [ ] Sistema de recomendaciones personalizado
- [ ] Compartir playlists entre usuarios
- [ ] API de exportación masiva
- [ ] Dashboard de analytics
- [ ] Mobile SDK

## 🤝 Contribución

1. Fork el proyecto
2. Crear branch de feature (`git checkout -b feature/nueva-feature`)
3. Commit cambios (`git commit -am 'Agregar nueva feature'`)
4. Push al branch (`git push origin feature/nueva-feature`)
5. Crear Pull Request

## 📝 License

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

## 🆘 Soporte

Para reportar bugs o solicitar features, crear un issue en GitHub o contactar al equipo de desarrollo.
