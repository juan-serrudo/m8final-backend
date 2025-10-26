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