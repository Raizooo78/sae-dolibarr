#!/bin/bash

set -e
cd "$(dirname "$0")"

docker compose exec -T db mariadb -uroot -proot dolibarr < backups/derniere/dolibarr.sql
docker compose exec -T web tar xzf - -C /var/www/documents < backups/derniere/documents.tar.gz
docker compose exec -T web sh -c 'cat > /var/www/html/conf/conf.php' < backups/derniere/conf.php

echo "Restauration faite"