# Frontend Despachos — Innovatech Chile

Interfaz web para la gestión de ventas y despachos de Innovatech Chile, desarrollada con React 18 + Vite + Tailwind CSS. Permite al equipo administrativo visualizar órdenes de compra, generar despachos y hacer seguimiento de entregas.

---

## Arquitectura

```
GitHub (push a main)
       │
       ▼
GitHub Actions (CI/CD)
  ├── npm ci + npm run build
  ├── Docker build & push → Amazon ECR
  └── Deploy → AWS ECS Fargate
                   │
             ┌─────┴──────┐
             │ Nginx :80  │  ← sirve el build estático
             └─────┬──────┘
                   │
         ┌─────────┴──────────┐
         │                    │
  back-ventas:8080   back-despachos:8081
   (API REST)          (API REST)
```

**Stack:**
- React 18 + Vite
- Tailwind CSS 3
- React Router DOM v6
- Axios (HTTP client)
- React Hook Form
- SweetAlert2 (notificaciones)
- Nginx (servidor en producción)
- Docker multietapa (Node → Nginx Alpine)
- AWS ECS Fargate + Amazon ECR
- CI/CD con GitHub Actions

---

## Funcionalidades

| Módulo | Descripción |
|---|---|
| **Tabla de Ventas** | Listado de órdenes de compra registradas en el sistema |
| **Generar Despacho** | Formulario para crear una orden de despacho asociada a una venta (fecha, patente del camión) |
| **Tabla de Despachos** | Listado de despachos con estado, intentos de entrega y datos del camión |
| **Cierre de Despacho** | Formulario para marcar un despacho como entregado |
| **Navbar** + **Footer** | Navegación y pie de página de la aplicación |

---

## Variables de entorno

La URL de los backends debe configurarse antes del build. Crea el archivo `.env.production` en la raíz del proyecto:

```bash
# .env.production
VITE_API_VENTAS_URL=http://<ALB-DNS>/api/v1/ventas
VITE_API_DESPACHOS_URL=http://<ALB-DNS>/api/v1/despachos
```

Para desarrollo local usa `.env.development`:

```bash
# .env.development
VITE_API_VENTAS_URL=http://localhost:8080/api/v1/ventas
VITE_API_DESPACHOS_URL=http://localhost:8081/api/v1/despachos
```

Luego en los componentes:
```js
const API_VENTAS = import.meta.env.VITE_API_VENTAS_URL;
const API_DESPACHOS = import.meta.env.VITE_API_DESPACHOS_URL;
```

>Los archivos `.env.*` están en `.gitignore`.
---

## Correr localmente con Docker

```bash
# 1. Clonar el repositorio
git clone https://github.com/<tu-usuario>/innovatech-frontend.git
cd innovatech-frontend

# 2. Crear el archivo de entorno de producción
echo "VITE_API_VENTAS_URL=http://localhost:8080/api/v1/ventas" > .env.production
echo "VITE_API_DESPACHOS_URL=http://localhost:8081/api/v1/despachos" >> .env.production

# 3. Build de la imagen
docker build -t frontend-innovatech:local .

# 4. Correr el contenedor
docker run -d -p 3000:80 frontend-innovatech:local

# 5. Abrir en el navegador
# http://localhost:3000
```

### Sin Docker (modo desarrollo)

```bash
# Instalar dependencias
npm install

# Crear archivo de entorno de desarrollo
echo "VITE_API_VENTAS_URL=http://localhost:8080/api/v1/ventas" > .env.development
echo "VITE_API_DESPACHOS_URL=http://localhost:8081/api/v1/despachos" >> .env.development

# Iniciar servidor de desarrollo
npm run dev
# Disponible en http://localhost:5173

# Build de producción
npm run build

# Preview del build
npm run preview
```

---

## Pipeline CI/CD (GitHub Actions)

El pipeline se encuentra en `.github/workflows/ci-cd.yml` y se activa automáticamente con cada `push` a la rama `main`.

### Flujo completo

```
push a main
    │
    ▼
[Job 1] build-and-push-ecr
    ├── Checkout código
    ├── Setup Node.js 20 (con caché npm)
    ├── npm ci
    ├── npm run build  ← genera /dist
    ├── Configurar credenciales AWS
    ├── Login en Amazon ECR
    └── docker build + tag + push (tag: SHA del commit + latest)
    │
    ▼
[Job 2] deploy-ecs
    ├── Obtener Task Definition actual
    ├── Actualizar imagen en Task Definition
    └── Registrar nueva TD y forzar redeploy en ECS
```

### Secrets requeridos en GitHub

Ir a **Settings → Secrets and variables → Actions** y agregar:

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access Key de AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de AWS Academy |
| `AWS_SESSION_TOKEN` | Session Token (renovar cada ~4h en Academy) |
| `AWS_REGION` | `us-east-1` |
| `AWS_ACCOUNT_ID` | ID de tu cuenta AWS (12 dígitos) |

---

## nfraestructura AWS

| Recurso | Valor |
|---|---|
| Clúster | `innovatech-cluster` (ECS Fargate) |
| Servicio ECS | `frontend` |
| Task Definition | `innovatech-frontend` |
| Imagen ECR | `<account>.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend` |
| Puerto | `80` (Nginx) |
| CPU / Memoria | 256 vCPU / 512 MB |
| Logs | CloudWatch `/ecs/innovatech/frontend` |
| Autoscaling | Target Tracking 50% CPU — mín. 1, máx. 4 tareas |
| Acceso público | URL del Application Load Balancer (ALB) |

### Ver logs en producción

```bash
# Seguir logs de Nginx en tiempo real
aws logs tail /ecs/innovatech/frontend --follow --region us-east-1
```

---

## Estructura del proyecto

```
frontend/
├── src/
│   ├── assets/
│   │   └── images/              # Logos e imágenes de la app
│   ├── componentes/
│   │   ├── CrudAdmin.jsx        # Layout principal (Navbar + contenido)
│   │   ├── CrudAdmin/
│   │   │   ├── TableCompras.jsx     # Tabla de órdenes de venta
│   │   │   ├── TableDespachos.jsx   # Tabla de despachos
│   │   │   ├── FormDespacho.jsx     # Formulario crear despacho
│   │   │   ├── FormCierreDespacho.jsx # Formulario cerrar despacho
│   │   │   ├── CardComponent.jsx    # Tarjeta de resumen
│   │   │   ├── PruebaCards.jsx      # Contenedor de cards
│   │   │   ├── Modal.jsx            # Componente modal reutilizable
│   │   │   └── SearchBar.jsx        # Barra de búsqueda
│   │   └── Layouts/
│   │       ├── Navbar.jsx       # Barra de navegación lateral
│   │       ├── Footer.jsx       # Pie de página
│   │       ├── Carrusel.jsx     # Carrusel de imágenes
│   │       └── Reviews.jsx      # Sección de reseñas
│   ├── Routes/
│   │   └── AppRoutes.jsx        # Definición de rutas (React Router)
│   ├── main.jsx                 # Entry point de la app
│   └── index.css                # Estilos globales + directivas Tailwind
├── public/
│   └── vite.svg
├── Dockerfile                   # Multietapa Node→Nginx
├── nginx.conf                   # Config del servidor Nginx
├── index.html
├── vite.config.js
├── tailwind.config.js
├── package.json
└── .github/
    └── workflows/
        └── ci-cd.yml
```

---

## Dependencias principales

| Paquete | Versión | Uso |
|---|---|---|
| `react` | ^18.2.0 | Framework UI |
| `react-dom` | ^18.2.0 | Renderizado DOM |
| `react-router-dom` | ^6.24.1 | Enrutamiento SPA |
| `axios` | ^1.6.8 | Llamadas HTTP a los backends |
| `react-hook-form` | ^7.52.1 | Manejo de formularios |
| `sweetalert2` | ^11.11.0 | Modales de confirmación/error |
| `react-icons` | ^5.1.0 | Iconografía |
| `tailwindcss` | ^3.4.3 | Utilidades CSS |



