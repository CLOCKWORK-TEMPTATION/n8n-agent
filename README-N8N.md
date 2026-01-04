# n8n Deployment with Docker Compose

This repository contains a complete n8n deployment setup with Docker Compose, featuring:

- **n8n workflow automation** with Queue Mode for scalability
- **PostgreSQL** database for persistent storage
- **Redis** for queue management
- **Qdrant** vector database for RAG (Retrieval-Augmented Generation) workflows
- **Nginx** reverse proxy with SSL/TLS support
- **Let's Encrypt** for automatic SSL certificate management
- **S3-compatible storage** configuration for binary data
- **Basic Authentication** for secure access

## Features

### 1. S3-Compatible Object Storage
Binary data can be stored in S3-compatible object storage. Configuration is available in the `.env` file.

### 2. Qdrant Vector Database
Qdrant is included for RAG workflows. A sample workflow is provided in `workflows/qdrant-rag-test.json`.

### 3. Queue Mode with Redis
Redis and n8n-worker are configured to enable Queue Mode for scalable workflow execution.

### 4. HTTPS with Nginx
Nginx acts as a reverse proxy with SSL/TLS support using Let's Encrypt certificates.

### 5. Basic Authentication
n8n is secured with Basic Authentication (username/password).

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- A domain name (for production with Let's Encrypt)
- Port 80 and 443 available (for Nginx)

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd n8n-agent
```

### 2. Configure Environment Variables

Copy and edit the `.env` file:

```bash
# Edit the .env file with your settings
nano .env
```

**Important settings to configure:**

- `POSTGRES_PASSWORD`: Change to a secure password
- `N8N_BASIC_AUTH_USER`: Your n8n username
- `N8N_BASIC_AUTH_PASSWORD`: Your n8n password
- `N8N_HOST`: Your domain name (e.g., `n8n.example.com`)
- `WEBHOOK_URL`: Your webhook URL (e.g., `https://n8n.example.com`)
- `QDRANT_API_KEY`: Your Qdrant API key (optional)
- `DOMAIN`: Your domain for Let's Encrypt
- `EMAIL`: Your email for Let's Encrypt notifications

### 3. Generate SSL Certificates

#### For Development (Self-Signed Certificate)

```bash
./generate-ssl-cert.sh
```

This creates a self-signed certificate in the `ssl/` directory.

#### For Production (Let's Encrypt)

First, make sure your domain points to your server's IP address.

Start the containers:

```bash
docker-compose up -d
```

Then run the Let's Encrypt setup script:

```bash
./setup-letsencrypt.sh
```

After obtaining the certificate, update `nginx.conf` to use the Let's Encrypt certificates (uncomment the Let's Encrypt lines and comment out the self-signed certificate lines).

Restart Nginx:

```bash
docker-compose restart nginx
```

### 4. Start the Services

```bash
docker-compose up -d
```

### 5. Access n8n

Open your browser and navigate to:

- **Development**: `https://localhost`
- **Production**: `https://your-domain.com`

Login with the credentials you set in the `.env` file:
- Username: Value of `N8N_BASIC_AUTH_USER`
- Password: Value of `N8N_BASIC_AUTH_PASSWORD`

## Configuration Details

### S3-Compatible Object Storage

To enable S3-compatible storage for binary data, uncomment and configure these variables in `.env`:

```env
N8N_DEFAULT_BINARY_DATA_MODE=s3
N8N_BINARY_DATA_S3_ENDPOINT=your-s3-endpoint.com
N8N_BINARY_DATA_S3_REGION=us-east-1
N8N_BINARY_DATA_S3_BUCKET_NAME=n8n-binary-data
N8N_BINARY_DATA_S3_ACCESS_KEY_ID=your-access-key
N8N_BINARY_DATA_S3_SECRET_ACCESS_KEY=your-secret-key
N8N_BINARY_DATA_S3_FORCE_PATH_STYLE=true
```

Then restart the n8n services:

```bash
docker-compose restart n8n n8n-worker
```

### Qdrant Configuration

Qdrant is accessible at `http://qdrant:6333` from within the Docker network.

To use Qdrant in your workflows:

1. Go to n8n Settings → Credentials
2. Add new credential → Qdrant API
3. Configure:
   - URL: `http://qdrant:6333`
   - API Key: The value from `QDRANT_API_KEY` in `.env`

You can test the Qdrant integration by importing the sample workflow:

```bash
# Import the sample workflow through the n8n UI
# File: workflows/qdrant-rag-test.json
```

### Queue Mode

Queue Mode is enabled by default with Redis. This allows:

- Scalable workflow execution
- Multiple worker instances
- Better resource management
- Improved reliability

The `n8n-worker` service handles workflow executions from the Redis queue.

### Basic Authentication

Basic Authentication is enabled by default. Configure in `.env`:

```env
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=change_this_secure_password
```

## Management Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f n8n-worker
docker-compose logs -f qdrant
```

### Stop Services

```bash
docker-compose down
```

### Stop and Remove Volumes (Warning: This deletes all data)

```bash
docker-compose down -v
```

### Restart a Specific Service

```bash
docker-compose restart n8n
docker-compose restart nginx
```

### Scale Workers

To add more worker instances for better performance:

```bash
docker-compose up -d --scale n8n-worker=3
```

## Service URLs

- **n8n UI**: `https://your-domain.com` (or `https://localhost` for development)
- **Qdrant UI**: `http://localhost:6333/dashboard` (direct access, not through Nginx)
- **Qdrant API**: `http://localhost:6333` (external) or `http://qdrant:6333` (internal)

## Backup

### Database Backup

```bash
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql
```

### Restore Database

```bash
docker-compose exec -T postgres psql -U n8n n8n < backup.sql
```

### Backup n8n Data

```bash
docker run --rm -v n8n-agent_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-data-backup.tar.gz /data
```

## Troubleshooting

### Certificate Issues

If you encounter certificate issues with Let's Encrypt:

1. Ensure your domain DNS is properly configured
2. Check that ports 80 and 443 are accessible
3. Review the certbot logs: `docker-compose logs certbot`

### Queue Mode Issues

If workflows are not executing:

1. Check Redis connection: `docker-compose logs redis`
2. Check worker logs: `docker-compose logs n8n-worker`
3. Verify Redis settings in `.env`

### Qdrant Connection Issues

If Qdrant is not accessible:

1. Check Qdrant logs: `docker-compose logs qdrant`
2. Verify the API key in `.env`
3. Ensure the Qdrant service is healthy: `docker-compose ps`

## Security Notes

- Change all default passwords in `.env`
- Use strong passwords for database and n8n authentication
- Keep your SSL certificates up to date
- Regularly update Docker images: `docker-compose pull && docker-compose up -d`
- Consider using secrets management for sensitive data
- Restrict access to ports 6333, 6334 (Qdrant) if not needed externally

## License

This project configuration is provided as-is for deploying n8n.

## Support

For n8n-specific issues, refer to the [official n8n documentation](https://docs.n8n.io/).
