cd "$(dirname "$0")"
 
#injecter le csv d'exemple dans la bdd
docker compose cp data/tiers.csv db:/tmp/tiers.csv
 
# Efface les anciens imports pour relancer et recharge le csv
docker compose exec -T db mariadb -uroot -proot --local-infile=1 dolibarr -e "
SET GLOBAL local_infile=1;
DELETE FROM llx_societe WHERE import_key='csv';
LOAD DATA LOCAL INFILE '/tmp/tiers.csv' INTO TABLE llx_societe
  FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (nom, client, fournisseur, @cc, @cf, address, zip, town, phone, @mail)
  SET code_client=NULLIF(@cc,''), code_fournisseur=NULLIF(@cf,''),
      email=TRIM(TRAILING '\r' FROM @mail),
      entity=1, fk_pays=1, datec=NOW(), import_key='csv';
SELECT nom, client, fournisseur, code_client, code_fournisseur FROM llx_societe WHERE import_key='csv';"