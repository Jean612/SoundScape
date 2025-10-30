# SoundScape API

SoundScape is a REST API built with Ruby on Rails that allows users to manage music playlists with secure authentication, intelligent AI-powered search, and export capabilities to platforms like Spotify and YouTube Music.

## 🎵 Key Features

- **JWT Authentication** with mandatory email confirmation.
- **Playlist and Song Management** with role-based authorization.
- **Intelligent AI Search** using Google Gemini for song suggestions.
- **Analytics System** for tracking searches and identifying trends.
- **Smart Caching** and rate limiting for performance optimization.
- **Export Functionality** to Spotify/YouTube Music (coming soon).

## 🛠 Technologies

- **Ruby** 3.2.2
- **Rails** 8.0 (API mode)
- **PostgreSQL** as the database
- **JWT** for authentication
- **CanCanCan** for authorization
- **Google Gemini AI** for intelligent search
- **RSpec** for testing
- **RuboCop** for code formatting

## 📋 System Requirements

- Ruby 3.2.2+
- PostgreSQL 12+
- Redis (for caching and rate limiting)
- Google Gemini API Key

## ⚙️ Configuration

### 1. Installation

```bash
# Clone the repository
git clone <repository-url>
cd SoundScape

# Install dependencies
bundle install

# Configure the database
rails db:create
rails db:migrate
```

### 2. Environment Variables

Create a `.env` file based on `.env.example`:

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

### 3. Obtain a Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey).
2. Create a new API key.
3. Add the key to your `.env` file.

## 🚀 Usage

### Starting the Server

```bash
rails server
```

### Main Endpoints

#### Authentication

```bash
# Registration
POST /api/v1/auth/register
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "name": "User Name",
    "username": "username123",
    "birth_date": "1990-01-01",
    "country": "USA"
  }
}

# Login (requires a confirmed email)
POST /api/v1/auth/login
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}

# Confirm Email
GET /api/v1/auth/confirm_email?token=CONFIRMATION_TOKEN
```

#### AI-Powered Search

```bash
# Search for songs using AI
POST /api/v1/ai_search
Authorization: Bearer JWT_TOKEN
{
  "query": "Beatles love songs",
  "limit": 5
}

# Get trending searches
GET /api/v1/ai_search/trending?limit=10&time_period=24

# User's search history
GET /api/v1/ai_search/history?page=1&per_page=20
```

#### Playlist Management

```bash
# Create a playlist
POST /api/v1/playlists
Authorization: Bearer JWT_TOKEN
{
  "playlist": {
    "name": "My Playlist",
    "description": "Optional description"
  }
}

# List the user's playlists
GET /api/v1/playlists
Authorization: Bearer JWT_TOKEN

# Add a song to a playlist
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
# Run all tests
rspec

# Run specific tests
rspec spec/models/
rspec spec/controllers/
rspec spec/services/

# With coverage details
rspec --format documentation
```

Currently, we have **107+ passing tests** with full coverage of:
- Models and validations
- Controllers and authentication
- AI and caching services
- Analytics and rate limiting

## 📊 AI Functionalities

### Intelligent Search

The system uses **Google Gemini 1.5 Flash** to generate intelligent song suggestions:

- **Caching**: Results are cached for 1 hour for improved performance.
- **Rate Limiting**: 60 searches per hour per user.
- **Validation**: Queries must be between 2 and 100 characters.
- **Fallback**: Provides a graceful response when the AI service is unavailable.

### Analytics and Trends

- **Search Tracking**: Records queries, timestamps, and results.
- **Trending Searches**: Identifies top queries in configurable time periods.
- **Personal History**: Paginated search history per user.
- **Anonymous Data**: IP addresses are used for analytics without personal identification.

## 🔒 Security

- **JWT Authentication** with secure tokens.
- **Mandatory Email Confirmation** before access is granted.
- **Rate Limiting** per user and endpoint.
- **Role-Based Authorization** with CanCanCan.
- **Exhaustive Input Validation**.
- **Secure Logs** with no exposure of sensitive data.

## 🚀 Deployment

### Production

1. Configure environment variables on the server.
2. Run migrations: `rails db:migrate RAILS_ENV=production`
3. Precompile assets: `rails assets:precompile RAILS_ENV=production`
4. Start the server: `rails server -e production`

### Docker (coming soon)

```bash
docker-compose up -d
```

## 📈 Roadmap

- [ ] Spotify API Integration
- [ ] YouTube Music API Integration
- [ ] Personalized Recommendation System
- [ ] Share playlists between users
- [ ] Bulk Export API
- [ ] Analytics Dashboard
- [ ] Mobile SDK

## 🤝 Contribution

1. Fork the project.
2. Create a feature branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Create a Pull Request.

## 📝 License

This project is licensed under the MIT License. See `LICENSE` for more details.

## 🆘 Support

To report bugs or request features, please create an issue on GitHub or contact the development team.
