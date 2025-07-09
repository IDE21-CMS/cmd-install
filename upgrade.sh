#!/bin/bash
sudo rm -r ./IDE21_upgrade
git clone https://github.com/nebojsatomic/IDE21.git IDE21_upgrade
IDE21_NEW_VERSION=$(cat ./IDE21_upgrade/.version)
echo $IDE21_NEW_VERSION
IDE21_OLD_VERSION=$(cat ./IDE21/.version)
echo $IDE21_OLD_VERSION

sudo mv ./IDE21 ./IDE21_$(echo $IDE21_OLD_VERSION)
sudo mv ./IDE21_upgrade ./IDE21

cd ./IDE21
docker compose down -v
docker rmi web:latest
cd ..


sudo mv ./IDE21/data ./IDE21/data_default
sudo mv ./IDE21/apache2 ./IDE21/apache2_default

# replace with setup files from the old version
sudo cp -r ./IDE21_$(echo $IDE21_OLD_VERSION)/data ./IDE21
sudo cp -r ./IDE21_$(echo $IDE21_OLD_VERSION)/apache2 ./IDE21
#sudo cp ./IDE21_$(echo $IDE21_OLD_VERSION)/docker-compose.yaml ./IDE21/docker-compose.yaml
sudo cp ./IDE21_$(echo $IDE21_OLD_VERSION)/src/legacy/dev-application/config/config.ini ./IDE21/src/legacy/dev-application/config/config.ini

cd ./IDE21
docker compose up -d

echo 'Upgraded to the latest version of IDE21'
