#!/bin/bash

set -e
cd "$(dirname "$0")"
DOSSIER="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DOSSIER"
 
docker compose exec -T db mariadb-dump -uroot -proot dolibarr > "$DOSSIER/dolibarr.sql"
docker compose exec -T web tar czf - -C /var/www/documents . > "$DOSSIER/documents.tar.gz"
docker compose exec -T web cat /var/www/html/conf/conf.php > "$DOSSIER/conf.php"
 
echo "Sauvegarde faite dans $DOSSIER"