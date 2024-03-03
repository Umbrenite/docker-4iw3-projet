# GROUPE 2 - 4IW3

## Commandes à utiliser
COMMANDE|DESCRIPTION                       |
-------------------------------|-----------------------------|
`docker compose -f docker-compose.yml -f docker-compose-db.yml build --no-cache`            | Build le projet en utilisant les deux fichiers docker-compose présents dans la structure            |
`docker compose up`            |Lancement du projet         |
`docker compose exec -it ${CONTAINER_NAME} sh`| Rentrer dans le conteneur _${CONTAINER_NAME}_ **[database, php, composer, adminer]**|

## Fonctionnalités
FONCTIONNALITÉ|FAIT/PAS FAIT                       |
-------------------------------|-----------------------------|
Projet fonctionnel           | Fait            |
Symfony custom et hébergé sur DockerHub            | Fait            |
Adminer custom et hébergé sur DockerHub            | Fait            |
Symfony custom et hébergé sur DockerHub            | Fait            |
Postgres custom et hébergé sur DockerHub            | Fait            |
Composer custom et hébergé sur DockerHub            | Fait            |
Installation de dépendances fonctionnelle avec Composer        | Fait            |
[BONUS] - Le Symfony et la BDD sur des docker-compose différents         | Fait            |
[ Lien vers le docker hub où sont partagés les images](https://hub.docker.com/u/umbrenite)
