set -e
cd "$(dirname "$0")"
DOSSIER="${1:-$(ls -d backups/* | tail -1)}"
 
docker compose exec -T db mariadb -uroot -proot dolibarr < "$DOSSIER/dolibarr.sql"
docker compose exec -T web tar xzf - -C /var/www/documents < "$DOSSIER/documents.tar.gz"
docker compose exec -T web sh -c 'cat > /var/www/html/conf/conf.php' < "$DOSSIER/conf.php"
 
echo "Restauration faite depuis $DOSSIER"