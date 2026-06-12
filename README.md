# Innovatech Chile – Frontend Despachos
> ISY1101 – Introducción a Herramientas DevOps | Evaluación Parcial N°2

## Descripción
Frontend de la aplicación de gestión de despachos y ventas de Innovatech Chile. Desarrollado en React + Vite y servido mediante Nginx en un contenedor Docker. Se comunica con los backends de Despachos y Ventas desplegados en AWS EC2.

## Stack Tecnológico
- **React + Vite** — framework frontend
- **Nginx Alpine** — servidor web en producción
- **Docker** — contenedorización con multi-stage build
- **Amazon ECR** — registro de imágenes
- **GitHub Actions** — pipeline CI/CD
- **AWS EC2** — despliegue en la nube

## Arquitectura

```
Usuario (Internet)
       │
       ▼
EC2 Pública – Puerto 80
  [Frontend React/Nginx]
       │
       ├──► EC2 Backend – Puerto 8081 (Despachos)
       └──► EC2 Backend – Puerto 8080 (Ventas)
                  │
                  ▼
             MySQL :3306
          (Named Volume)
```

## Estructura del Proyecto

```
├── src/
│   ├── componentes/
│   │   └── CrudAdmin/
│   │       ├── TableDespachos.jsx    # Tabla de despachos
│   │       └── TableCompras.jsx      # Tabla de ventas
│   └── main.jsx
├── Dockerfile                        # Multi-stage build
├── .github/
│   └── workflows/
│       └── deploy.yml               # Pipeline CI/CD
├── .env.example                     # Variables requeridas
├── .gitignore
└── package.json
```

## Dockerfile – Multi-Stage Build

El Dockerfile implementa dos etapas:

1. **Builder**: usa `node:20-alpine` para compilar el proyecto React con Vite
2. **Runtime**: usa `nginx:alpine` para servir los archivos estáticos compilados

Características de seguridad:
- Usuario no-root (`appuser`) en la etapa de runtime
- Imagen final sin herramientas de build (~25MB vs ~900MB con Node completo)
- Cache de capas optimizado (dependencias separadas del código)

## Variables de Entorno

Copia `.env.example` a `.env` y completa los valores:

```bash
cp .env.example .env
```

| Variable | Descripción | Ejemplo |
|---|---|---|
| `VITE_BACKEND_DESPACHOS_URL` | URL del backend de despachos | `http://IP_BACKEND:8081` |
| `VITE_BACKEND_VENTAS_URL` | URL del backend de ventas | `http://IP_BACKEND:8080` |

## Ejecutar Localmente

### Con Docker

```bash
# Construir imagen
docker build \
  --build-arg VITE_BACKEND_DESPACHOS_URL=http://localhost:8081 \
  --build-arg VITE_BACKEND_VENTAS_URL=http://localhost:8080 \
  -t innovatech-frontend .

# Ejecutar contenedor
docker run -d \
  --name frontend \
  -p 80:80 \
  innovatech-frontend

# Acceder en: http://localhost
```

### Sin Docker (desarrollo)

```bash
npm install
npm run dev
```

## Pipeline CI/CD

El pipeline se activa automáticamente con **push en la rama `deploy`**:

```
push → deploy
    ↓
1. Checkout del código
    ↓
2. Configurar credenciales AWS
    ↓
3. Login a Amazon ECR
    ↓
4. Build imagen Docker (multi-stage)
    ↓
5. Push imagen a ECR con tag del commit SHA
    ↓
6. Deploy en EC2 vía SSH (docker pull + docker run)
```

### Secrets requeridos en GitHub

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS |
| `AWS_SESSION_TOKEN` | Token de sesión temporal |
| `AWS_ACCOUNT_ID` | ID de cuenta AWS |
| `EC2_FRONTEND_HOST` | IP pública de la EC2 frontend |
| `EC2_SSH_KEY` | Contenido del archivo .pem |
| `EC2_BACKEND_HOST` | IP del backend (para build-arg) |

## Convención de Commits

```
feat:   nueva funcionalidad
fix:    corrección de bug
docker: cambios en contenedorización
ci:     cambios en pipeline CI/CD
docs:   actualización de documentación
```

## Despliegue en AWS

La imagen se publica en Amazon ECR:
```
757001429093.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest
```

El contenedor se ejecuta en la instancia EC2 pública con el puerto 80 expuesto a internet.

## Principios DevOps Aplicados

- **Contenedorización**: imagen reproducible y portable
- **CI/CD**: despliegue automático sin intervención manual
- **Mínimo privilegio**: usuario no-root en el contenedor
- **Control de versiones**: ramas separadas (main/deploy)
- **Infraestructura como código**: Dockerfile y workflow en Git
