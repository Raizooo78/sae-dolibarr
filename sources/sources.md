Explications de nos choix techniques:

1) Utilisation de Docker
La finalité du projet est de pouvoir déployer Dolibarr en un clic sur une machine vierge.

Donc pour la demande de plan de reprise d'activité cette solution répond aussi au cahier des charges

La base de données est aussi mise dans un conteneur permettant portabilité et sécurité. 


2) Le Dockerfile:

Ce fichier est lié au déploiement Docker, il contient une suite d'instructions et de commandes pas à pas pour construire une image Docker personnalisée. 

On a préféré créer notre propre image au lieu d'en prendre une toute faite. 
Cela permet de respecter la consigne d'utiliser la version "source" de Dolibarr et de gérer nous-mêmes l'installation.

Liens qui nous ont aidé :

- Image Debian 11 : https://hub.docker.com/_/debian
- Github de Dolibarr: https://github.com/Dolibarr/dolibarr/
  (On récupère l'archive Dolibarr avec wget)
- Le wiki pour voir les prérequis (PHP, Apache) : https://wiki.dolibarr.org/

3) Le docker-compose.yml:

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
