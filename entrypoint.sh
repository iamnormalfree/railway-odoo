#!/bin/bash

set -euo pipefail

echo "Waiting for database..."

while ! nc -z "${ODOO_DATABASE_HOST}" "${ODOO_DATABASE_PORT}" 2>&1; do sleep 1; done;

echo "Database is now available"

# Note: Odoo 18 prefers non-superuser database accounts for security
# For Railway deployment, we'll use the provided postgres user
# and configure Odoo to accept it via config file

echo "Using database user: ${ODOO_DATABASE_USER}"

ALLOW_DATABASE_MANAGER=${ODOO_ALLOW_DATABASE_MANAGER:-false}
MASTER_PASSWORD=${ODOO_MASTER_PASSWORD:-admin}
CONFIG_PATH=${ODOO_RC:-/tmp/odoo.conf}

if [ "$ALLOW_DATABASE_MANAGER" = "true" ]; then
    echo "Database manager enabled (list_db = True)"
    LIST_DB_VALUE="True"
else
    echo "Database manager disabled (list_db = False)"
    LIST_DB_VALUE="False"
fi

cat > "$CONFIG_PATH" <<EOFCONF
[options]
list_db = ${LIST_DB_VALUE}
admin_passwd = ${MASTER_PASSWORD}
EOFCONF

export ODOO_RC="$CONFIG_PATH"

exec odoo \
    -c "${CONFIG_PATH}" \
    --http-port="${PORT}" \
    --proxy-mode \
    --db_host="${ODOO_DATABASE_HOST}" \
    --db_port="${ODOO_DATABASE_PORT}" \
    --db_user="${ODOO_DATABASE_USER}" \
    --db_password="${ODOO_DATABASE_PASSWORD}" \
    --database="${ODOO_DATABASE_NAME}" \
    --smtp="${ODOO_SMTP_HOST}" \
    --smtp-port="${ODOO_SMTP_PORT_NUMBER}" \
    --smtp-user="${ODOO_SMTP_USER}" \
    --smtp-password="${ODOO_SMTP_PASSWORD}" \
    --email-from="${ODOO_EMAIL_FROM}" \
    2>&1
