#!/bin/sh

set -e

echo "Waiting for database..."

while ! nc -z ${ODOO_DATABASE_HOST} ${ODOO_DATABASE_PORT} 2>&1; do sleep 1; done;

echo "Database is now available"

# Create dedicated Odoo database user if using default postgres user
# Odoo 18 requires non-superuser for security
if [ "${ODOO_DATABASE_USER}" = "postgres" ]; then
    echo "Creating dedicated Odoo database user..."
    export PGPASSWORD="${ODOO_DATABASE_PASSWORD}"

    # Create odoo user if it doesn't exist
    psql -h "${ODOO_DATABASE_HOST}" -p "${ODOO_DATABASE_PORT}" -U postgres -d postgres -tc \
        "SELECT 1 FROM pg_user WHERE usename = 'odoo'" | grep -q 1 || \
    psql -h "${ODOO_DATABASE_HOST}" -p "${ODOO_DATABASE_PORT}" -U postgres -d postgres -c \
        "CREATE USER odoo WITH PASSWORD '${ODOO_DATABASE_PASSWORD}' CREATEDB;"

    echo "Using dedicated odoo user"
    export ODOO_DB_USER="odoo"
else
    export ODOO_DB_USER="${ODOO_DATABASE_USER}"
fi

exec odoo \
    --http-port="${PORT}" \
    --init=all \
    --without-demo=True \
    --proxy-mode \
    --db_host="${ODOO_DATABASE_HOST}" \
    --db_port="${ODOO_DATABASE_PORT}" \
    --db_user="${ODOO_DB_USER}" \
    --db_password="${ODOO_DATABASE_PASSWORD}" \
    --database="${ODOO_DATABASE_NAME}" \
    --smtp="${ODOO_SMTP_HOST}" \
    --smtp-port="${ODOO_SMTP_PORT_NUMBER}" \
    --smtp-user="${ODOO_SMTP_USER}" \
    --smtp-password="${ODOO_SMTP_PASSWORD}" \
    --email-from="${ODOO_EMAIL_FROM}" 2>&1