#!/bin/bash
set -euo pipefail

# Конфігураційний файл для зберігання credential
MYSQL_CNF="/etc/mysql/backup.cnf"
BACKUP_DIR="/var/backups/mysql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Перевірка наявності конфігураційного файлу
if [[ ! -f "$MYSQL_CNF" ]]; then
    echo "Помилка: конфігураційний файл $MYSQL_CNF не знайдено" >&2
    exit 1
fi

# Створення директорії для бекапів
mkdir -p "$BACKUP_DIR"

# Логування помилок
exec > >(tee -a "$BACKUP_DIR/backup.log") 2>&1

# Повне резервне копіювання ShopDB
FULL_BACKUP_FILE="$BACKUP_DIR/ShopDB_full_$TIMESTAMP.sql"
mysqldump --defaults-extra-file="$MYSQL_CNF" \
    --single-transaction --routines --triggers --events \
    ShopDB > "$FULL_BACKUP_FILE"

# Відновлення в ShopDBReserve
mysql --defaults-extra-file="$MYSQL_CNF" -e \
    "DROP DATABASE IF EXISTS ShopDBReserve; CREATE DATABASE ShopDBReserve;"
mysql --defaults-extra-file="$MYSQL_CNF" ShopDBReserve < "$FULL_BACKUP_FILE"

# Копіювання даних в ShopDBDevelopment
DATA_BACKUP_FILE="$BACKUP_DIR/ShopDB_data_$TIMESTAMP.sql"
mysqldump --defaults-extra-file="$MYSQL_CNF" \
    --no-create-info --skip-triggers --skip-routines \
    ShopDB > "$DATA_BACKUP_FILE"

mysql --defaults-extra-file="$MYSQL_CNF" ShopDBDevelopment < "$DATA_BACKUP_FILE"

# Очистка старих бекапів
find "$BACKUP_DIR" -name '*.sql' -mtime +7 -exec rm {} \;
