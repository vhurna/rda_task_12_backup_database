#!/bin/bash

# Ініціалізація змінних
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DB_HOST="localhost"
BACKUP_DIR="/var/backups/mysql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Перевірка змінних оточення
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "Помилка: DB_USER або DB_PASSWORD не встановлені" >&2
    exit 1
fi

# Створення директорії для бекапів
mkdir -p "$BACKUP_DIR"

# Повне резервне копіювання ShopDB
FULL_BACKUP_FILE="$BACKUP_DIR/ShopDB_full_$TIMESTAMP.sql"
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
    --single-transaction --routines --triggers --events \
    ShopDB > "$FULL_BACKUP_FILE"

# Відновлення в ShopDBReserve
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
    -e "DROP DATABASE IF EXISTS ShopDBReserve; CREATE DATABASE ShopDBReserve;"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
    ShopDBReserve < "$FULL_BACKUP_FILE"

# Копіювання даних в ShopDBDevelopment
DATA_BACKUP_FILE="$BACKUP_DIR/ShopDB_data_$TIMESTAMP.sql"
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
    --no-create-info --skip-triggers --skip-routines \
    ShopDB > "$DATA_BACKUP_FILE"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
    ShopDBDevelopment < "$DATA_BACKUP_FILE"

# Очистка старих бекапів
find "$BACKUP_DIR" -name '*.sql' -mtime +7 -exec rm {} \;
#! /bin/bash
