# Quick Start Guide

This guide helps you quickly get n8n up and running with all configured services.

## Prerequisites Check

- [ ] Docker installed (version 20.10+)
- [ ] Docker Compose installed (version 2.0+)
- [ ] Ports 80, 443, 5678 available
- [ ] (Optional) Domain name for production SSL

## Setup Steps

### 1. Configure Environment (5 minutes)

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your settings
nano .env
```

**Required changes in .env:**
- `POSTGRES_PASSWORD`: Set a strong password
- `N8N_BASIC_AUTH_USER`: Your username
- `N8N_BASIC_AUTH_PASSWORD`: Your password
- `N8N_HOST`: Your domain or `localhost`
- `WEBHOOK_URL`: Your webhook URL

**Optional for production:**
- `DOMAIN`: Your domain name
- `EMAIL`: Your email for Let's Encrypt

### 2. Generate SSL Certificate

**For Development:**
```bash
./generate-ssl-cert.sh
```

**For Production:**
See README-N8N.md for Let's Encrypt setup instructions.

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Access n8n

Open your browser:
- Development: https://localhost
- Production: https://your-domain.com

Login with credentials from `.env`:
- Username: `N8N_BASIC_AUTH_USER`
- Password: `N8N_BASIC_AUTH_PASSWORD`

## What's Configured

✅ **PostgreSQL Database** - Persistent workflow storage
✅ **Redis** - Queue management for scalability
✅ **Queue Mode** - Scalable execution with n8n-worker
✅ **Qdrant** - Vector database for RAG workflows
✅ **Nginx** - Reverse proxy with SSL/TLS
✅ **Basic Auth** - Secured access to n8n
✅ **S3 Support** - Ready for S3-compatible storage

## Testing Qdrant Integration

1. In n8n, go to **Settings** → **Credentials**
2. Add **Qdrant API** credential:
   - URL: `http://qdrant:6333`
   - API Key: (from your `.env` file)
3. Import the test workflow: `workflows/qdrant-rag-test.json`
4. Run the workflow to test Qdrant connectivity

## Enable S3 Storage

Uncomment these lines in `.env`:

```env
N8N_DEFAULT_BINARY_DATA_MODE=s3
N8N_BINARY_DATA_S3_ENDPOINT=your-s3-endpoint.com
N8N_BINARY_DATA_S3_REGION=us-east-1
N8N_BINARY_DATA_S3_BUCKET_NAME=n8n-binary-data
N8N_BINARY_DATA_S3_ACCESS_KEY_ID=your-access-key
N8N_BINARY_DATA_S3_SECRET_ACCESS_KEY=your-secret-key
```

Then restart:
```bash
docker-compose restart n8n n8n-worker
```

## Common Commands

```bash
# View all logs
docker-compose logs -f

# Restart n8n
docker-compose restart n8n

# Stop all services
docker-compose down

# Scale workers (add more workers)
docker-compose up -d --scale n8n-worker=3

# Check service health
docker-compose ps
```

## Troubleshooting

### Cannot access n8n
- Check if containers are running: `docker-compose ps`
- Check logs: `docker-compose logs n8n`
- Verify ports are not in use: `sudo netstat -tulpn | grep :443`

### Qdrant not working
- Check Qdrant logs: `docker-compose logs qdrant`
- Verify API key in `.env` matches credential in n8n
- Access Qdrant UI: http://localhost:6333/dashboard

### SSL Certificate Issues
- For development, regenerate: `./generate-ssl-cert.sh`
- For production, see Let's Encrypt setup in README-N8N.md

## Next Steps

1. Create your first workflow
2. Set up Qdrant credentials
3. Test the sample RAG workflow
4. Configure S3 storage if needed
5. Scale workers for production workload

For detailed documentation, see [README-N8N.md](./README-N8N.md)
