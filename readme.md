# sae-dolibarr

**Projet SAE51**

Le projet donné a pour but de permettre de déployer facilement et automatiquement une version de l'ERP Dolibarr avec sa BDD sur une machine vierge ou dans le cas d'un plan de reprise d'activité.

Grossomodo, Dolibarr est un logiciel prévu pour gérer les activités administratives d'une entreprises via une interface web. 

Nous utilisons donc Docker afin de permettre une mise en conteneur de l'appli Dolibarr et isoler la base de données qui l'accompagne. 

Pour se faire, Docker et quelques scripts d'automatisation permettront à un client de récupérer une appli fonctionnelle simplement. 

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

6) **Script de sauvegarde de la BDD *backup.sh***


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