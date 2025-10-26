# 🔐 Password Manager Monorepo

A secure password management system built with a modern monorepo architecture, featuring a NestJS backend, React frontend, and unified deployment with Docker.

## 📁 Project Structure

```
m8final-backend/
├── backend/                 # NestJS Backend Application
│   ├── src/                 # Source code
│   ├── dist/                # Compiled JavaScript
│   ├── test/                # Backend tests
│   ├── Dockerfile           # Backend container configuration
│   └── package.json         # Backend dependencies
├── frontend/                # React + Vite Frontend Application
│   ├── src/                 # Source code
│   ├── public/              # Static assets
│   ├── Dockerfile           # Frontend container configuration
│   └── package.json         # Frontend dependencies
├── nginx/                   # Nginx Configuration
│   └── nginx.conf           # Reverse proxy configuration
├── deploy/                  # Deployment Scripts
│   ├── start.sh            # Start all services
│   ├── stop.sh             # Stop all services
│   └── health-check.sh      # Health monitoring
├── docker-compose.yml       # Multi-service orchestration
├── env.example             # Environment variables template
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Node.js 20+ (for local development)
- Git

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd m8final-backend

# Copy environment configuration
cp env.example .env

# Review and update .env file if needed
```

### 2. Start the Application

```bash
# Make scripts executable
chmod +x deploy/*.sh

# Start all services
./deploy/start.sh
```

### 3. Access the Application

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3000
- **API Documentation**: http://localhost:3000/api-docs
- **Health Check**: http://localhost:8080/health

## 🛠️ Development

### Backend Development

```bash
cd backend

# Install dependencies
npm install

# Start in development mode
npm run start:dev

# Run tests
npm run test

# Run migrations
npm run migration:run
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm run test

# Build for production
npm run build
```

### Full Stack Development

For full-stack development with hot reloading:

```bash
# Terminal 1: Backend
cd backend && npm run start:dev

# Terminal 2: Frontend
cd frontend && npm run dev

# Terminal 3: Database (optional, if not using Docker)
# Start PostgreSQL and Redis locally
```

## 🐳 Docker Services

The application consists of the following services:

### Core Services

- **postgres**: PostgreSQL 16 database
- **redis**: Redis 7 cache
- **app**: NestJS backend API
- **frontend**: React + Vite frontend
- **nginx**: Reverse proxy and load balancer

### Service Ports

- **80**: Nginx (main entry point)
- **8080**: Nginx (alternative port)
- **3000**: Backend API (direct access)
- **5432**: PostgreSQL
- **6379**: Redis

## 🔧 Configuration

### Environment Variables

Key environment variables (see `env.example` for complete list):

```bash
# Backend Configuration
NODE_ENV=production
PORT=3000
DB_HOST=postgres
DB_PASSWORD=your_secure_password

# Frontend Configuration
VITE_API_BASE_URL=http://localhost:3000/api

# Database Configuration
POSTGRES_DB=password_manager
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
```

### Nginx Configuration

The nginx service acts as a reverse proxy:

- `/api/*` → Backend API
- `/api-docs` → API Documentation
- `/health` → Health Check
- `/*` → Frontend SPA (with fallback to index.html)

## 🧪 Testing

### Backend Tests

```bash
cd backend

# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Test coverage
npm run test:cov
```

### Frontend Tests

```bash
cd frontend

# Run tests
npm run test

# Run tests with UI
npm run test:ui

# Test coverage
npm run test:coverage
```

### Health Checks

```bash
# Check all services
./deploy/health-check.sh

# Check specific service
curl http://localhost:8080/health
curl http://localhost:3000/health
```

## 📊 Monitoring

### Health Endpoints

- **Overall Health**: `GET /health`
- **Backend Health**: `GET /api/health`
- **Database Health**: Included in backend health check
- **Cache Health**: Included in backend health check

### Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f frontend
docker-compose logs -f nginx
```

## 🚀 Deployment

### Production Deployment

1. **Update Environment Variables**:
   ```bash
   cp env.example .env
   # Edit .env with production values
   ```

2. **Build and Start**:
   ```bash
   ./deploy/start.sh
   ```

3. **Verify Deployment**:
   ```bash
   ./deploy/health-check.sh
   ```

### Scaling

To scale specific services:

```bash
# Scale backend instances
docker-compose up -d --scale app=3

# Scale frontend instances
docker-compose up -d --scale frontend=2
```

## 🔒 Security Features

- **Password Encryption**: AES encryption with master key
- **CORS Configuration**: Configurable cross-origin policies
- **Rate Limiting**: Throttling to prevent abuse
- **Health Checks**: Comprehensive monitoring
- **Non-root Containers**: Security-hardened Docker images
- **Environment Isolation**: Separate development/production configs

## 📚 API Documentation

Once the application is running, visit:
- **Swagger UI**: http://localhost:3000/api-docs
- **OpenAPI Spec**: http://localhost:3000/api-docs-json

### Key API Endpoints

- `GET /api/password-manager/` - List all passwords
- `POST /api/password-manager/` - Create new password
- `PUT /api/password-manager/:id` - Update password
- `DELETE /api/password-manager/:id` - Delete password
- `POST /api/password-manager/:id/decrypt` - Decrypt password

## 🛠️ Troubleshooting

### Common Issues

1. **Port Conflicts**:
   ```bash
   # Check what's using the ports
   lsof -i :80 -i :3000 -i :5432 -i :6379
   ```

2. **Database Connection Issues**:
   ```bash
   # Check database logs
   docker-compose logs postgres
   ```

3. **Frontend Not Loading**:
   ```bash
   # Check nginx logs
   docker-compose logs nginx
   ```

4. **Build Failures**:
   ```bash
   # Rebuild without cache
   docker-compose build --no-cache
   ```

### Reset Everything

```bash
# Stop and remove everything
docker-compose down -v --rmi all

# Remove all containers and images
docker system prune -a

# Start fresh
./deploy/start.sh
```

## 📝 Development Workflow

### Adding New Features

1. **Backend**: Add to `backend/src/`
2. **Frontend**: Add to `frontend/src/`
3. **Tests**: Add corresponding tests
4. **Documentation**: Update this README

### Code Quality

```bash
# Backend linting
cd backend && npm run lint

# Frontend linting
cd frontend && npm run lint

# Format code
cd backend && npm run format
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- **Issues**: Create a GitHub issue
- **Documentation**: Check this README and API docs
- **Health Check**: Run `./deploy/health-check.sh`

---

**Happy Coding! 🚀**