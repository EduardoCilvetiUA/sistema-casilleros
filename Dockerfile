# syntax = docker/dockerfile:1

# Este Dockerfile está diseñado para producción.
# Construcción:
# docker build -t my-app .
# Ejecución:
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<valor de config/master.key> my-app

# Asegúrate de que RUBY_VERSION coincide con la versión de Ruby en .ruby-version
ARG RUBY_VERSION=3.3.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Directorio de trabajo de la aplicación Rails
WORKDIR /rails

# Instalar paquetes base necesarios para producción
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configurar variables de entorno para producción
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

# Fase de construcción para reducir el tamaño de la imagen final
FROM base AS build

# Instalar paquetes necesarios para compilar gemas
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copiar y instalar las gemas de la aplicación
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copiar el código de la aplicación
COPY . .

# Precompilar código de bootsnap para mejorar tiempos de arranque
RUN bundle exec bootsnap precompile app/ lib/

# Precompilar assets para producción sin requerir el RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Fase final de la imagen de la aplicación
FROM base

# Copiar artefactos construidos: gemas y código de la aplicación
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Crear usuario no root para ejecutar la aplicación
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp

# Cambiar al usuario sin privilegios
USER rails:rails

# Configurar el ENTRYPOINT para preparar la base de datos
COPY ./bin/docker-entrypoint /rails/bin/docker-entrypoint
RUN chmod +x /rails/bin/docker-entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Exponer el puerto predeterminado de Rails
EXPOSE 3000

# Comando por defecto para iniciar el servidor
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
