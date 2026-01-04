# Deployment Verification Checklist

Use this checklist to verify your n8n deployment is configured correctly.

## Pre-Deployment Verification

### Configuration Files Present
- [ ] `docker-compose.yml` exists
- [ ] `.env` file exists and is configured
- [ ] `nginx.conf` exists
- [ ] SSL certificates generated (dev) or Let's Encrypt configured (prod)

### Environment Variables Configured
- [ ] `POSTGRES_PASSWORD` set to a secure password
- [ ] `N8N_BASIC_AUTH_USER` configured
- [ ] `N8N_BASIC_AUTH_PASSWORD` set to a secure password
- [ ] `N8N_HOST` set to your domain or localhost
- [ ] `WEBHOOK_URL` configured correctly
- [ ] `QDRANT_API_KEY` set (if using Qdrant)
- [ ] `DOMAIN` and `EMAIL` set (for Let's Encrypt)
- [ ] `N8N_DEFAULT_BINARY_DATA_MODE` set (filesystem or s3)

### S3 Configuration (if using S3)
- [ ] `N8N_DEFAULT_BINARY_DATA_MODE=s3` set
- [ ] `N8N_BINARY_DATA_S3_ENDPOINT` configured
- [ ] `N8N_BINARY_DATA_S3_REGION` configured
- [ ] `N8N_BINARY_DATA_S3_BUCKET_NAME` configured
- [ ] `N8N_BINARY_DATA_S3_ACCESS_KEY_ID` set
- [ ] `N8N_BINARY_DATA_S3_SECRET_ACCESS_KEY` set

## Deployment Verification

### Services Running
```bash
docker-compose ps
```
- [ ] postgres: Up and healthy
- [ ] redis: Up and healthy
- [ ] qdrant: Up and healthy
- [ ] n8n: Up and healthy
- [ ] n8n-worker: Up and running
- [ ] nginx: Up and healthy
- [ ] certbot: Up

### Service Health Checks
```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready -U n8n

# Check Redis
docker-compose exec redis redis-cli ping

# Check Qdrant
curl http://localhost:6333/healthz

# Check n8n
curl http://localhost:5678/healthz

# Check Nginx (internal)
docker-compose exec nginx wget --spider http://localhost/health
```

### Port Accessibility
- [ ] Port 80 accessible (HTTP redirect)
- [ ] Port 443 accessible (HTTPS)
- [ ] Port 6333 accessible (Qdrant UI, if needed externally)

### SSL/TLS Configuration
- [ ] HTTPS redirects working (HTTP → HTTPS)
- [ ] SSL certificate valid (not self-signed warnings in production)
- [ ] Security headers present (check browser dev tools)

## Functional Verification

### n8n Access
- [ ] Can access n8n UI via HTTPS
- [ ] Basic Authentication prompts for credentials
- [ ] Can login with configured credentials
- [ ] n8n UI loads correctly

### Qdrant Integration
- [ ] Can access Qdrant dashboard at http://localhost:6333/dashboard
- [ ] Can create Qdrant credentials in n8n
- [ ] Can import sample RAG workflow
- [ ] Sample workflow executes successfully

### Queue Mode
- [ ] Workflows execute on worker (check logs)
- [ ] Redis queue is processing jobs
- [ ] Worker logs show execution activity

### Data Persistence
```bash
# Stop and restart services
docker-compose down
docker-compose up -d

# Verify data persists
```
- [ ] Workflows persist after restart
- [ ] Credentials persist after restart
- [ ] Execution history persists after restart

## Security Verification

### Authentication
- [ ] Basic Authentication is enabled
- [ ] Cannot access n8n without credentials
- [ ] Default passwords changed from examples

### Network Security
- [ ] Services only accessible through Nginx (except direct ports if needed)
- [ ] PostgreSQL not accessible externally
- [ ] Redis not accessible externally
- [ ] Internal Docker network configured correctly

### SSL/TLS
- [ ] Certificate is valid and trusted (production)
- [ ] HSTS header present
- [ ] TLS 1.2+ only
- [ ] Strong ciphers configured

### Secrets Management
- [ ] No secrets in docker-compose.yml
- [ ] All secrets in .env file
- [ ] .env file not committed to git
- [ ] File permissions correct on .env (600)

## Performance Verification

### Worker Scaling
```bash
# Scale to 3 workers
docker-compose up -d --scale n8n-worker=3
docker-compose ps
```
- [ ] Multiple workers running
- [ ] Load distributed across workers
- [ ] No errors in worker logs

### Resource Usage
```bash
docker stats
```
- [ ] Reasonable CPU usage
- [ ] Reasonable memory usage
- [ ] No memory leaks over time

## Backup Verification

### Database Backup
```bash
docker-compose exec postgres pg_dump -U n8n n8n > backup-test.sql
ls -lh backup-test.sql
```
- [ ] Backup created successfully
- [ ] Backup file has reasonable size
- [ ] Can restore from backup (test in dev)

### Volume Backup
```bash
docker run --rm -v n8n-agent_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-test.tar.gz /data
ls -lh n8n-test.tar.gz
```
- [ ] Volume backup created
- [ ] Backup contains expected data

## Monitoring Setup (Optional)

### Logs
```bash
docker-compose logs -f
```
- [ ] Logs are readable
- [ ] No persistent errors
- [ ] Log rotation configured (if needed)

### Health Endpoints
- [ ] `/healthz` endpoints responding
- [ ] Can set up external monitoring (if needed)

## Documentation Verification

- [ ] README-N8N.md reviewed
- [ ] QUICKSTART.md followed successfully
- [ ] ARCHITECTURE.md understood
- [ ] REQUIREMENTS.md all items checked ✅

## Production Checklist

### Before Going Live
- [ ] All tests above passed
- [ ] Backups configured and tested
- [ ] Monitoring set up
- [ ] SSL certificate from Let's Encrypt (not self-signed)
- [ ] All default passwords changed
- [ ] Domain DNS configured correctly
- [ ] Firewall rules configured
- [ ] Resource limits set (if needed)
- [ ] Log rotation configured
- [ ] Update policy defined

### Post-Deployment
- [ ] Create first production workflow
- [ ] Test webhook endpoints
- [ ] Verify email notifications (if configured)
- [ ] Set up regular backups (cron job)
- [ ] Document deployment details
- [ ] Share access credentials securely
- [ ] Schedule maintenance windows

## Troubleshooting

If any checks fail, refer to:
1. README-N8N.md → Troubleshooting section
2. Check service logs: `docker-compose logs [service-name]`
3. Verify environment variables in .env
4. Check Docker network: `docker network inspect n8n-agent_default`
5. Review nginx configuration for proxy issues
6. Verify SSL certificate validity and paths

## Support Resources

- n8n Documentation: https://docs.n8n.io/
- Qdrant Documentation: https://qdrant.tech/documentation/
- Docker Compose Documentation: https://docs.docker.com/compose/
- Nginx Documentation: https://nginx.org/en/docs/

---

**Deployment Status**: 
- [ ] All pre-deployment checks passed
- [ ] All deployment checks passed
- [ ] All functional checks passed
- [ ] All security checks passed
- [ ] Ready for production use

**Date**: _____________
**Deployed by**: _____________
**Environment**: [ ] Development  [ ] Staging  [ ] Production
