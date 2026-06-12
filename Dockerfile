# Etapa 1: Build React
FROM node:20-alpine AS builder
WORKDIR /app
 
# Instalar dependencias
COPY package*.json ./
RUN npm ci --silent
 

COPY . .
# Construir con la URL del backend inyectada como variable de entorno
ARG VITE_BACKEND_DESPACHOS_URL=http://localhost:8081
ARG VITE_BACKEND_VENTAS_URL=http://localhost:8080
ENV VITE_BACKEND_DESPACHOS_URL=$VITE_BACKEND_DESPACHOS_URL
ENV VITE_BACKEND_VENTAS_URL=$VITE_BACKEND_VENTAS_URL
RUN npm run build
 
# Etapa 2: Nginx 
FROM nginx:alpine AS runtime
 
# Crear usuario no-root y asignar permisos
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /usr/share/nginx/html \
    && chown -R appuser:appgroup /var/cache/nginx
 
# Copiar build
COPY --from=builder /app/dist /usr/share/nginx/html
 
# Configuración nginx para SPA (React Router)
RUN printf 'server {\n  listen 80;\n  root /usr/share/nginx/html;\n  index index.html;\n  location / { try_files $uri $uri/ /index.html; }\n}\n' \
    > /etc/nginx/conf.d/default.conf
 
USER appuser
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
