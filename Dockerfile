# Dockerfile para SoundScape API - Rails en Render

# --- Etapa 1: Base ---
FROM ruby:3.2.2-slim as base

# Instala dependencias del sistema
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Establece el directorio de trabajo.
WORKDIR /rails

# --- Etapa 2: Build ---
# Esta etapa instala las dependencias y precompila los assets.
FROM base as build

# Copia los archivos de dependencias y las instala.
# Esto aprovecha el caché de Docker para acelerar futuras construcciones.
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs $(nproc) --retry 3

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copia el resto del código de la aplicación.
COPY . .

# Precompila los assets para producción.
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# --- Etapa 3: Production ---
# Esta es la imagen final. Es ligera porque no incluye las herramientas de construcción.
FROM base as production

# Copia las gemas instaladas desde la etapa 'build'.
COPY --from=build /usr/local/bundle/ /usr/local/bundle/

# Copia el código de la aplicación (incluyendo los assets precompilados) desde 'build'.
COPY --from=build /rails /rails

# Expone el puerto 3000, donde se ejecutará la aplicación.
EXPOSE 3000

# Crea un usuario no-root para mayor seguridad
RUN groupadd --gid 1000 rails \
  && useradd --uid 1000 --gid rails --shell /bin/bash --create-home rails

# Cambia la propiedad de los archivos
RUN chown -R rails:rails /rails
USER rails:rails

# El comando para iniciar el servidor Puma en modo producción.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]