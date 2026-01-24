#!/usr/bin/env bash

set -euo pipefail

DB_HOST="${ODOO_DATABASE_HOST:-${PGHOST:-}}"
DB_PORT="${ODOO_DATABASE_PORT:-${PGPORT:-5432}}"
DB_USER="${ODOO_DATABASE_USER:-${PGUSER:-}}"
DB_PASSWORD="${ODOO_DATABASE_PASSWORD:-${PGPASSWORD:-}}"
HTTP_PORT="${PORT:-8069}"

ALLOW_DATABASE_MANAGER="${ODOO_ALLOW_DATABASE_MANAGER:-false}"
MASTER_PASSWORD="${ODOO_MASTER_PASSWORD:-${ODOO_MASTER_PWD:-}}"
DEFAULT_DB="${ODOO_DATABASE_NAME:-}"

CONFIG_PATH="${ODOO_RC:-/tmp/odoo.conf}"

if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "ERROR: Missing database connection env vars." >&2
  echo "Expected: ODOO_DATABASE_HOST/USER/PASSWORD (or PGHOST/PGUSER/PGPASSWORD fallbacks)." >&2
  exit 2
fi

if [[ -z "$MASTER_PASSWORD" ]]; then
  echo "WARNING: ODOO_MASTER_PASSWORD not set; defaulting master password to 'admin'." >&2
  MASTER_PASSWORD="admin"
fi

LIST_DB_VALUE="False"
case "$(printf '%s' "$ALLOW_DATABASE_MANAGER" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes|y) LIST_DB_VALUE="True" ;;
esac

echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
while ! nc -z "$DB_HOST" "$DB_PORT" 2>&1; do sleep 1; done
echo "Database is now available"

echo "Writing Odoo config to: $CONFIG_PATH"
cat > "$CONFIG_PATH" <<EOFCONF
[options]
proxy_mode = True
admin_passwd = ${MASTER_PASSWORD}
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
list_db = ${LIST_DB_VALUE}
EOFCONF

if [[ -n "$DEFAULT_DB" ]]; then
  echo "db_name = ${DEFAULT_DB}" >> "$CONFIG_PATH"
fi

if [[ -n "${ODOO_SMTP_HOST:-}" ]]; then
  echo "smtp_server = ${ODOO_SMTP_HOST}" >> "$CONFIG_PATH"
fi
if [[ -n "${ODOO_SMTP_PORT_NUMBER:-}" ]]; then
  echo "smtp_port = ${ODOO_SMTP_PORT_NUMBER}" >> "$CONFIG_PATH"
fi
if [[ -n "${ODOO_SMTP_USER:-}" ]]; then
  echo "smtp_user = ${ODOO_SMTP_USER}" >> "$CONFIG_PATH"
fi
if [[ -n "${ODOO_SMTP_PASSWORD:-}" ]]; then
  echo "smtp_password = ${ODOO_SMTP_PASSWORD}" >> "$CONFIG_PATH"
fi
if [[ -n "${ODOO_EMAIL_FROM:-}" ]]; then
  echo "email_from = ${ODOO_EMAIL_FROM}" >> "$CONFIG_PATH"
fi

export ODOO_RC="$CONFIG_PATH"

if [[ -n "$DEFAULT_DB" ]]; then
  echo "Single-database mode enabled via ODOO_DATABASE_NAME=${DEFAULT_DB} (the ?db= param will be ignored)."
else
  echo "Multi-database mode enabled (ODOO_DATABASE_NAME is unset)."
fi

echo "Database manager/listing enabled: ${LIST_DB_VALUE}"
echo "Starting Odoo on port: ${HTTP_PORT}"

exec odoo -c "$CONFIG_PATH" --http-port="$HTTP_PORT" --proxy-mode 2>&1
