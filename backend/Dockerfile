# Construcción multi-etapa para backend NestJS
FROM node:20-alpine AS base

# Instalar dependencias necesarias para módulos nativos
RUN apk add --no-cache python3 make g++

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de paquetes
COPY package*.json ./
COPY yarn.lock ./

# Instalar dependencias
RUN yarn install --frozen-lockfile

# Copiar código fuente
COPY . .

# Construir la aplicación
RUN yarn build

# Etapa de producción
FROM node:20-alpine AS production

# Instalar dependencias necesarias para SQLite y otros módulos nativos
RUN apk add --no-cache sqlite

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 -G nodejs

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de paquetes
COPY package*.json ./
COPY yarn.lock ./

# Instalar solo dependencias de producción
RUN yarn install --production --frozen-lockfile && yarn cache clean

# Copiar aplicación construida desde la etapa base
COPY --from=base /app/dist ./dist
COPY --from=base /app/src ./src

# Crear directorio de datos para SQLite
RUN mkdir -p /app/data && \
    chown -R nestjs:nodejs /app

# Cambiar a usuario no-root
USER nestjs

# Exponer puerto
EXPOSE 3000

# Verificación de salud
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000

# Iniciar la aplicación
CMD ["node", "dist/main.js"]