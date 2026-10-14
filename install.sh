set -e
cd "$(dirname "$0")"
 
# on build l'img et on lance les 2 conteneurs
docker compose up -d --build
sleep 6.7
 
INSTALL="docker compose exec -T -u www-data -w /var/www/html/install web"
$INSTALL php step1.php set auto /var/www/html /var/www/documents http://localhost:8080 "" "" mysqli db dolibarr dolibarr_user dolibarr_pwd 3306 llx_ "" ""
$INSTALL php step2.php set auto
$INSTALL php step5.php 0 0 auto set admin admin admin 444
 
docker compose exec -T -u www-data -w /var/www/html web php -r 'require_once "master.inc.php"; require_once DOL_DOCUMENT_ROOT."/core/lib/admin.lib.php"; activateModule("modSociete");'
 
echo "Dolibarr ok : http://localhost:8080   (login : admin / admin)"
 