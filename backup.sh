#!/bin/bash

set -e
cd "$(dirname "$0")"
rm -rf backups/en_cours && mkdir backups/en_cours
 
docker compose exec -T db mariadb-dump -uroot -proot dolibarr > backups/en_cours/dolibarr.sql
docker compose exec -T web tar czf - -C /var/www/documents . > backups/en_cours/documents.tar.gz
docker compose exec -T web cat /var/www/html/conf/conf.php > backups/en_cours/conf.php
 
# remplacement de l'ancienne sauvegarde par la nouvelle
rm -rf backups/derniere && mv backups/en_cours backups/derniere
echo "Sauvegarde faite dans backups/derniere"