# docker-4iw3-projet
docker compose -f docker-compose.yml -f docker-compose-db.yml build --no-cache  -> Build avec les deux fichiers docker-compose.yml

docker compose -f docker-compose.yml -f docker-compose-db.yml up -d             -> Lancement des 4 conteneurs

docker compose exec -it database sh                                             -> Rentrer dans le conteneur database
docker compose exec -it composer sh                                             -> Rentrer dans le conteneur composer
docker compose exec -it symfony sh                                              -> Rentrer dans le conteneur symfony
docker compose exec -it adminer sh                                              -> Rentrer dans le conteneur adminer

ping ${NOM_CONTENEUR}                                                           -> Tester la connexion avec les autres conteneurs