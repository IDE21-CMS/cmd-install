#!/bin/bash
sudo rm -r ./IDE21_upgrade
git clone https://github.com/nebojsatomic/IDE21.git IDE21_upgrade
IDE21_NEW_VERSION=$(cat ./IDE21_upgrade/.version)
echo $IDE21_NEW_VERSION
IDE21_OLD_VERSION=$(cat ./IDE21/.version)
echo $IDE21_OLD_VERSION

#sudo mv ./IDE21_upgrade ./IDE21_$(echo $IDE21_NEW_VERSION)

sudo mv ./IDE21 ./IDE21_$(echo $IDE21_OLD_VERSION)
sudo mv ./IDE21_upgrade ./IDE21
