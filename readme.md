# sae-dolibarr

**Projet SAE51**

Le projet donné a pour but de permettre de déployer facilement et automatiquement une version de l'ERP Dolibarr avec sa BDD sur une machine vierge ou dans le cas d'un plan de reprise d'activité.

Grossomodo, Dolibarr est un logiciel prévu pour gérer les activités administratives d'une entreprises via une interface web. 

Nous utilisons donc Docker afin de permettre une mise en conteneur de l'appli Dolibarr et isoler la base de données qui l'accompagne. 

Pour se faire, Docker et quelques scripts d'automatisation permettront à un client de récupérer une appli fonctionnelle simplement. 

# Comment lancer le projet

**Avant de commencer**
- Avoir **Docker** installé (sous Windows : Docker Desktop).
- Sous Windows, utiliser un terminal **Ubuntu (WSL)** et pas PowerShell. Dans Docker Desktop : *Settings > Resources > WSL integration* et cocher Ubuntu.

**1. Récupérer le projet** (dans le terminal Ubuntu)
```bash
cd ~
git clone https://github.com/Raizooo78/sae-dolibarr.git
cd sae-dolibarr
```

**2. Tout installer**
```bash
./install.sh
```
Ça prend quelques minutes. Quand « Dolibarr ok » s'affiche, c'est prêt : Dolibarr est installé, les 4 tiers du CSV sont importés et la sauvegarde de 18h est programmée.

**3. Ouvrir Dolibarr**
- Adresse : http://localhost:8080
- Login : `admin` / mot de passe : `admin`
- Les tiers sont dans *Third parties > List*.

**4. Sauvegarder et restaurer**
```bash
./backup.sh      # sauvegarde (se fait aussi tout seul chaque jour à 18h)
./restore.sh     # remet la dernière sauvegarde (à lancer après ./install.sh)
```

**5. Tout supprimer pour recommencer de zéro**
```bash
docker compose down -v
```

**Test de reprise après incident (PRA)**
```bash
./backup.sh && docker compose down -v && ./install.sh && ./restore.sh
```

*Si « Permission denied » : `chmod +x *.sh`. Sous Ubuntu (WSL), pour que la sauvegarde de 18h tourne : `sudo service cron start`.*

# Prise en main de Dolibarr sur une VM

Avant de passer à Docker, on a installé Dolibarr à la main sur une VM Debian 13 (Proxmox de l'IUT). Le but n'était pas de faire le projet sur la VM, mais de comprendre comment un déploiement fonctionne et de voir ce que les scripts devront automatiser.

* Installation d'Apache, de PHP et de MariaDB, puis de Dolibarr (version 24.0.1 sur la VM, 18.0.1 dans notre Docker) avec son assistant d'installation web.
* Création de la base de données et de son utilisateur. Une erreur MariaDB 1044 est apparue : l'utilisateur n'avait pas les droits sur la base, réglé avec `GRANT ALL PRIVILEGES` puis `FLUSH PRIVILEGES`.
* Activation des modules **Tiers**, **Data imports** et **Data exports**.
* Export CSV des entreprises depuis Dolibarr, pour voir le format de sortie du fichier. Cela a servi de modèle pour notre fichier `data/entreprise.csv`.

# Explications de nos choix techniques:

1) **Utilisation de Docker**
La finalité du projet est de pouvoir déployer Dolibarr en un clic sur une machine vierge.

Donc pour la demande de plan de reprise d'activité cette solution répond aussi au cahier des charges

La base de données est aussi mise dans un conteneur permettant portabilité et sécurité. 


2) **Le Dockerfile:**

Ce fichier est lié au déploiement Docker, il contient une suite d'instructions et de commandes pas à pas pour construire une image Docker personnalisée. 

On a préféré créer notre propre image au lieu d'en prendre une toute faite. 
Cela permet de respecter la consigne d'utiliser la version "source" de Dolibarr et de gérer nous-mêmes l'installation.

Liens qui nous ont aidé :

- Image Debian 11 : https://hub.docker.com/_/debian
- Github de Dolibarr: https://github.com/Dolibarr/dolibarr/
  (On récupère l'archive Dolibarr avec wget)
- Le wiki pour voir les prérequis (PHP, Apache) : https://wiki.dolibarr.org/

3) **Le docker-compose.yml:**

Au lieu de tout installer sur un seul système, on a fait le choix de séparer l'architecture en deux conteneurs distincts : 
un dédié au serveur web (Apache/PHP + Dolibarr) et un dédié exclusivement à la base de données. 

Conteneur web : nécessite un serveur web d'où Apache et d'un moteur d'éxecution ici PHP

3.1/ Fonctionnement 
Le fichier docker-compose lie nos deux conteneurs dans un réseau privé. 
La base de données n'est donc pas exposée directement sur le réseau de la VM . 

Le serveur web communique avec la BDD simplement en utilisant le nom du service ("db") défini dans le compose.
L'avantage est qu'on ne se soucie pas des IP

On peut dans le docker-compose définir le mot de passe de la BDD permettant de lier le serveur web à la BDD automatiquement.
On n'aura donc pas besoin de configurer l'accès à la BDD manuellemet

Liens :
- Le repo du prof pour la structure MariaDB : https://github.com/skramm/but3_rt/tree/main/docker_BDD
- Image officielle MariaDB : https://hub.docker.com/_/mariadb


4) **Script d'import des données clients via un csv *import_csv.sh***

Ce script permet d'injecter les données clients d'un fichier CSV vers la base de données de l'ERP

* **`#!/bin/bash`** : shebang pour rendre exécutable le fichier .sh
* **`cd "$(dirname "$0")"`** : on se place à la racine du projet
* **`docker compose cp data/entreprise.csv db:/tmp/tiers.csv`** : copie le fichier local `entreprise.csv` vers le conteneur *db* dans le chemin `/tmp/tiers.csv`.
* **`docker compose exec -T db mariadb -uroot -proot --local-infile=1 dolibarr -e "..."`** : Lance le client MariaDB à l'intérieur du conteneur `db` avec user root et password root pour se connecter à la base `dolibarr`.`--local-infile=1` autorise la lecture de notre fichier CSV.
* **`SET GLOBAL local_infile=1;`** : autorise le serveur BDD à accepter l'importation de fichiers locaux 
* **`DELETE FROM llx_societe WHERE import_key='csv';`** : gestion de doublon avec suppression préalable
* **`LOAD DATA LOCAL INFILE '/tmp/tiers.csv' INTO TABLE llx_societe ...`** : On charge les données du csv dans la table `llx_societe` de Dolibarr.
* **`SELECT nom, client...`** : on print les nouvelles données pour confirmer l'ajout au client


5) **Script pour restaurer à l'état X l'appli et sa BDD *restore.sh***

Ce script remet en place ce que *backup.sh* a sauvegardé. Il se lance **après `./install.sh`**, pour que les conteneurs existent.

* **`set -e`** : arrête le script à la première erreur.
* **`cd "$(dirname "$0")"`** : on se place à la racine du projet.
* **`docker compose exec -T db mariadb -uroot -proot dolibarr < backups/derniere/dolibarr.sql`** : rejoue la sauvegarde SQL dans la base. Les tables sont remplacées par celles de la sauvegarde, c'est ce qui redonne les tiers.
* **`docker compose exec -T web tar xzf - -C /var/www/documents < backups/derniere/documents.tar.gz`** : décompresse les documents sauvegardés dans le conteneur web.
* **`docker compose exec -T web sh -c 'cat > /var/www/html/conf/conf.php' < backups/derniere/conf.php`** : remet le fichier de configuration de Dolibarr.

6) **Script de sauvegarde de la BDD *backup.sh***

Ce script fait une copie de l'état de l'application dans le dossier `backups/derniere/`.

* **`rm -rf backups/en_cours && mkdir -p backups/en_cours`** : crée un dossier de travail propre (le `-p` crée aussi `backups/` s'il n'existe pas).
* **`mariadb-dump ... > dolibarr.sql`** : copie toute la base de données dans un fichier SQL.
* **`tar czf ... > documents.tar.gz`** : compresse les documents de Dolibarr.
* **`cat conf.php > conf.php`** : copie le fichier de configuration.
* **`rm -rf backups/derniere && mv backups/en_cours backups/derniere`** : la nouvelle sauvegarde remplace celle de la veille, seulement si tout s'est bien passé. En cas d'échec, l'ancienne reste intacte.
* Le script est lancé tous les jours à 18h par le CRON mis en place dans *install.sh*.


**Cas d'installation classique**

Le projet vise à être déployé simplement sur une machine Debian client en exécutant le fichier *install.sh*. 
Une fois les conteneurs en place, nous avons intégré l'éxecution de *import_csv.sh*.
Ainsi, le lancement de la commande ./install.sh permettrait de déployer l'ERP Dolibarr et l'import des données client issu du fichier csv. 

**Mise en place d'un CRON pour l'éxecution journalière du script backup.sh**

Le script *backup.sh* permet de figer et sauvegarder la BDD dans l'état. 
Pour éviter la perte de données sur la BDD suite à un oubli de lancement du script backup.sh, la mise en place d'un CRON a été envisagé.

Un CRON est une tâche automatique pouvant être défini qui peut se lancer selon une durée donné permettant le lancement de script sans action direct d'un humain.
* Dans notre cas, on a mis en place un CRON permettant tous les soirs de lancer *backup.sh* enregistrant la BDD dans son état. Cet état figé est enregsitré dans le dossier ()

**Nécessité d'un restore suite à un CRASH**

Dans le cas où l'ERP est déployé, est en place et que ce dernier subit un CRASH nécessitant une réinstallation, la conteneurisation de l'application simplifie la tache.

La commande ./restore.sh permet de revenir au stade de la dernière sauvegarde émise par le CRON.