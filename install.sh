#!/bin/bash
set -e
cd "$(dirname "$0")"
 
# on installe docker et build l'img et on lance les 2 conteneurs
command -v docker >/dev/null || sudo apt-get install -y docker.io docker-compose-v2
docker compose up -d --build
sleep 30
 
INSTALL="docker compose exec -T -u www-data -w /var/www/html/install web"
$INSTALL php step1.php set auto /var/www/html /var/www/documents http://localhost:8080 "" "" mysqli db dolibarr dolibarr_user dolibarr_pwd 3306 llx_ "" ""
$INSTALL php step2.php set auto
$INSTALL php step5.php 0 0 auto set admin admin admin 444
 
docker compose exec -T -u www-data -w /var/www/html web php -r 'require_once "master.inc.php"; require_once DOL_DOCUMENT_ROOT."/core/lib/admin.lib.php"; activateModule("modSociete"); activateModule("modFournisseur");'
# lancement de l'importation du csv dans la bdd
bash import_csv.sh

# sauvegarde automatique de la bdd à la fin de journée

command -v crontab >/dev/null || sudo apt-get install -y cron
(crontab -l 2>/dev/null | grep -v backup.sh; echo "0 18 * * * cd $PWD && ./backup.sh >> backups/cron.log 2>&1") | crontab -

echo "Dolibarr ok : http://localhost:8080   (login : admin / admin)"
 