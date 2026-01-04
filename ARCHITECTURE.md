# n8n Deployment Architecture

## System Overview

This deployment provides a complete, production-ready n8n automation platform with the following architecture:

```
                                    Internet
                                       |
                                       |
                              [Port 80/443]
                                       |
                                       v
                            +-------------------+
                            |      Nginx        |
                            | (Reverse Proxy)   |
                            |   + SSL/TLS       |
                            +-------------------+
                                       |
                                       | HTTPS
                                       v
                            +-------------------+
                            |       n8n         |
                            |  (Main Instance)  |
                            | + Basic Auth      |
                            +-------------------+
                                       |
              +------------------------+------------------------+
              |                        |                        |
              v                        v                        v
     +----------------+      +------------------+      +------------------+
     |  PostgreSQL    |      |     Redis        |      |     Qdrant       |
     |  (Database)    |      | (Queue Service)  |      | (Vector Store)   |
     +----------------+      +------------------+      +------------------+
              ^                        ^                        ^
              |                        |                        |
              +------------------------+------------------------+
                                       |
                                       v
                            +-------------------+
                            |   n8n-worker      |
                            | (Queue Executor)  |
                            +-------------------+
```

## Components

### 1. Nginx (Reverse Proxy)
- **Purpose**: SSL/TLS termination and reverse proxy
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Features**:
  - Automatic HTTP to HTTPS redirect
  - SSL certificate support (Let's Encrypt or self-signed)
  - WebSocket support for n8n
  - Security headers (HSTS, X-Frame-Options, etc.)
  - Rate limiting
  - 100MB upload limit for workflows

### 2. n8n (Main Instance)
- **Purpose**: Workflow automation platform
- **Port**: 5678 (internal)
- **Features**:
  - Web UI for workflow creation
  - Webhook endpoints
  - Queue Mode enabled
  - Basic Authentication
  - PostgreSQL for persistence
  - S3-compatible storage support
  - Qdrant integration

### 3. PostgreSQL
- **Purpose**: Persistent storage for n8n data
- **Version**: 15-alpine
- **Stores**:
  - Workflow definitions
  - Execution history
  - Credentials (encrypted)
  - Settings

### 4. Redis
- **Purpose**: Queue management for distributed execution
- **Version**: 7-alpine
- **Features**:
  - Bull queue for workflow jobs
  - Persistent data storage
  - Health monitoring

### 5. n8n-worker
- **Purpose**: Executes workflows from Redis queue
- **Features**:
  - Scalable (can run multiple instances)
  - Shared storage with main n8n instance
  - Same database connection
  - Automatic job pickup from Redis

### 6. Qdrant
- **Purpose**: Vector database for RAG workflows
- **Ports**: 6333 (HTTP), 6334 (gRPC)
- **Features**:
  - Vector similarity search
  - API key authentication
  - Persistent storage
  - Web UI dashboard

### 7. Certbot
- **Purpose**: SSL certificate management
- **Features**:
  - Let's Encrypt integration
  - Automatic certificate renewal
  - ACME challenge support

## Data Flow

### Workflow Execution (Queue Mode)

```
User → Nginx → n8n → PostgreSQL (save workflow)
                  ↓
                Redis (queue job)
                  ↓
            n8n-worker (execute)
                  ↓
           Qdrant/External APIs
```

### RAG Workflow with Qdrant

```
n8n Workflow → Embed Text → Qdrant (Insert Vector)
                                  ↓
                            Vector Database
                                  ↓
n8n Workflow ← Search Results ← Qdrant (Search)
```

## Security Features

### 1. Network Security
- All external traffic through Nginx
- SSL/TLS encryption
- Internal Docker network for service communication
- No direct external access to databases

### 2. Authentication
- Basic Authentication for n8n UI
- Qdrant API key authentication
- PostgreSQL password protection
- Redis isolated to internal network

### 3. Data Security
- Encrypted credentials in PostgreSQL
- HTTPS for all external communication
- Security headers (HSTS, CSP-ready)
- Rate limiting on Nginx

## Scalability

### Horizontal Scaling
```bash
# Scale workers for increased throughput
docker-compose up -d --scale n8n-worker=5
```

### Vertical Scaling
- Increase container resources in docker-compose.yml
- Add resource limits and reservations

### Queue Benefits
- Asynchronous execution
- Load distribution
- Failure recovery
- Better resource utilization

## Storage

### Persistent Volumes
- `postgres_data`: PostgreSQL database
- `redis_data`: Redis persistence
- `qdrant_storage`: Qdrant vectors
- `n8n_data`: n8n workflows and binary data
- `certbot_data`: SSL certificates
- `certbot_www`: ACME challenge files

### Binary Data Options

#### Option 1: Filesystem (Default)
```
n8n_data volume → Shared across n8n and workers
```

#### Option 2: S3-Compatible Storage
```
n8n → S3 API → Object Storage (MinIO, AWS S3, etc.)
                     ↑
              n8n-worker
```

## Monitoring and Health

### Health Checks
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`
- Qdrant: HTTP `/healthz` endpoint
- n8n: HTTP `/healthz` endpoint
- Nginx: HTTP `/health` endpoint

### Logging
```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f n8n
docker-compose logs -f n8n-worker
docker-compose logs -f qdrant
```

## Environment Configuration

### Critical Variables
- `N8N_BASIC_AUTH_ACTIVE=true` - Enable authentication
- `EXECUTIONS_MODE=queue` - Enable Queue Mode
- `QUEUE_BULL_REDIS_HOST=redis` - Queue configuration
- `N8N_HOST` - Your domain
- `QDRANT_API_KEY` - Qdrant authentication

### Optional Variables
- S3 storage configuration
- Timezone settings
- Email settings (for Let's Encrypt)

## Deployment Scenarios

### Development
1. Use `docker-compose.dev.yml` override
2. Self-signed SSL certificates
3. Direct access to n8n:5678 (optional)
4. Single worker instance

### Production
1. Full docker-compose.yml
2. Let's Encrypt SSL certificates
3. Access only through Nginx
4. Multiple worker instances
5. External S3 storage
6. Regular backups

## Backup Strategy

### What to Backup
1. PostgreSQL database (workflows, executions)
2. n8n_data volume (binary data, if not using S3)
3. Qdrant storage (vector database)
4. SSL certificates

### Backup Commands
```bash
# Database
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql

# n8n data
docker run --rm -v n8n-agent_n8n_data:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/n8n-backup.tar.gz /data
```

## Troubleshooting Flow

```
Issue Detected
     |
     v
Check Service Status (docker-compose ps)
     |
     v
View Logs (docker-compose logs)
     |
     v
Check Health Endpoints
     |
     v
Verify Environment Variables
     |
     v
Check Network Connectivity
     |
     v
Review Configuration Files
```

## Performance Tuning

### For High Load
- Increase worker count
- Optimize PostgreSQL settings
- Use Redis persistent storage
- Configure resource limits
- Enable caching

### For Low Latency
- Use SSD for volumes
- Increase Redis memory
- Optimize network settings
- Use local object storage

## Integration Points

### n8n ↔ Qdrant
- HTTP API on port 6333
- API key authentication
- Environment variables passed to workflows

### n8n ↔ PostgreSQL
- Standard PostgreSQL connection
- Connection pooling
- Encrypted credential storage

### n8n ↔ Redis
- Bull queue library
- Job serialization
- Worker coordination

## Next Steps

1. Deploy the stack: `docker-compose up -d`
2. Configure SSL certificates
3. Set up Qdrant credentials in n8n
4. Import test workflow
5. Scale workers based on load
6. Set up monitoring
7. Configure backups
8. Enable S3 storage (optional)

---

For detailed setup instructions, see [README-N8N.md](./README-N8N.md)
For quick start, see [QUICKSTART.md](./QUICKSTART.md)
