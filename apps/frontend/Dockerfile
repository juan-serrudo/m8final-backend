# builder: marca la etapa de construcción.
# Usa la imagen base Node 20 (Alpine) y nombra la etapa builder.
FROM node:20-alpine AS builder

# Crea (si no existe) y establece /app como directorio de trabajo.
WORKDIR /app

# Copia los manifiestos de dependencias. Mejora la caché de capas.
COPY package*.json ./

# Copia el lockfile para instalar dependencias exactas.
COPY yarn.lock ./

# Instala dependencias respetando el yarn.lock (sin actualizar versiones).
RUN yarn install --frozen-lockfile

# Copia el resto del código fuente al contenedor (ignorando lo de .dockerignore).
COPY . .

# Compila/genera el build de producción (normalmente en dist/).
RUN yarn build


# Etapa de producción con nginx
FROM nginx:alpine AS production

# Copiar configuración personalizada de nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar aplicación construida (se construye localmente)
COPY dist /usr/share/nginx/html

# Establecer permisos apropiados
RUN chown -R nginx:nginx /usr/share/nginx/html

# Exponer puerto 80
EXPOSE 80

# Verificación de salud
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Iniciar nginx
CMD ["nginx", "-g", "daemon off;"]