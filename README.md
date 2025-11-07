# Railway Odoo 18 Template

Deploy [Odoo 18](https://www.odoo.com/) ERP on Railway with PostgreSQL in minutes.

## Features

- **Odoo 18.0** - Latest stable release with all modern features
- **Safe Redeploys** - Data persists across Railway service restarts
- **Configurable Database Manager** - Enable/disable database creation UI
- **SMTP Support** - Built-in email configuration
- **Security Hardened** - Runs as non-root user, database manager disabled by default

## Quick Deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/odoo18)

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ODOO_DATABASE_HOST` | PostgreSQL host | `postgres.railway.internal` |
| `ODOO_DATABASE_PORT` | PostgreSQL port | `5432` |
| `ODOO_DATABASE_USER` | PostgreSQL username | `postgres` |
| `ODOO_DATABASE_PASSWORD` | PostgreSQL password | `your-secure-password` |
| `ODOO_DATABASE_NAME` | Database name for Odoo | `odoo` |
| `PORT` | HTTP port for Odoo web server | `8000` (Railway sets this) |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ODOO_ALLOW_DATABASE_MANAGER` | Enable database creation UI (`true`/`false`) | `false` |
| `ODOO_MASTER_PASSWORD` | Master password for database operations | `admin` |
| `ODOO_SMTP_HOST` | SMTP server hostname | (none) |
| `ODOO_SMTP_PORT_NUMBER` | SMTP server port | `587` |
| `ODOO_SMTP_USER` | SMTP username | (none) |
| `ODOO_SMTP_PASSWORD` | SMTP password | (none) |
| `ODOO_EMAIL_FROM` | Default "From" email address | (none) |

## Safe Deployment Workflow

**IMPORTANT:** This template is designed for safe redeployment. Follow this workflow:

### Initial Setup (First Deployment)

1. **Enable Database Manager** temporarily:
   ```bash
   ODOO_ALLOW_DATABASE_MANAGER=true
   ```

2. **Deploy** and wait for Railway to start the service

3. **Create Database** via Odoo web UI:
   - Visit your Railway app URL
   - Click "Create Database"
   - Enter database name (must match `ODOO_DATABASE_NAME`)
   - Set strong master password
   - Select language and demo data preferences

4. **Disable Database Manager** for security:
   ```bash
   ODOO_ALLOW_DATABASE_MANAGER=false
   ```

5. **Redeploy** - Your data persists across restarts

### Production Security

**NEVER** leave `ODOO_ALLOW_DATABASE_MANAGER=true` in production:
- Exposes database creation UI to public
- Allows database management operations
- Security risk for production deployments

**Safe workflow:** Enable → Create DB → Disable → Lock down production

## Customization

### Using Odoo Shell

If you need to run custom Python code in Odoo's environment:

```bash
# Connect to Railway service
railway connect

# Start Odoo shell
odoo shell --database=your-database-name

# In Python shell - ALWAYS commit transactions:
>>> # Your code here
>>> env.cr.commit()  # CRITICAL: Commit changes
>>> exit()
```

**WARNING:** `env.cr.commit()` is REQUIRED in Odoo shell. Without it, changes are rolled back when shell exits.

### Adding Custom Modules

Mount custom modules via Railway volumes:

```dockerfile
# In your custom Dockerfile
FROM ghcr.io/your-org/railway-odoo:latest
COPY ./custom-addons /mnt/extra-addons
```

Then set in environment:
```bash
ODOO_ADDONS_PATH=/mnt/extra-addons
```

## Troubleshooting

### Database Connection Fails

- Verify PostgreSQL service is running on Railway
- Check `ODOO_DATABASE_HOST` and `ODOO_DATABASE_PORT`
- Ensure database user has CREATE DATABASE privileges

### Data Loss on Redeploy

This template **prevents** data loss by:
- **NOT using `--init=all` flag** (causes module reinitialization)
- Using persistent PostgreSQL database
- Config-based database manager control

If you experience data loss, ensure:
1. PostgreSQL is persistent (Railway volume mounted)
2. `ODOO_DATABASE_NAME` matches created database
3. No custom `--init` flags in modified entrypoint

### Database Manager Not Showing

Set `ODOO_ALLOW_DATABASE_MANAGER=true` and redeploy.

## Architecture

```
┌─────────────────────────────────────┐
│ Railway Container (Odoo 18)         │
│ ├─ entrypoint.sh (startup script)   │
│ ├─ odoo (web server on $PORT)       │
│ └─ /tmp/odoo.conf (generated config)│
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│ Railway PostgreSQL Service          │
│ - Persistent volume for data        │
│ - Automatic backups (paid plans)    │
└─────────────────────────────────────┘
```

## License

This Railway template is MIT licensed. Odoo itself is LGPL v3.

## Contributing

Issues and PRs welcome at [github.com/your-org/railway-odoo](https://github.com/your-org/railway-odoo)

## Related

- [Odoo Official Documentation](https://www.odoo.com/documentation/18.0/)
- [Railway Documentation](https://docs.railway.app/)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don%27t_Do_This)
