#!/bin/bash
#Ставим судо
apt-get install sudo
#Собираем данные по пользователям
echo "Введите пользователя для добавления в группу sudo"
read s
echo "Введите пользователя для добавления в группу docker"
read d
#Добавляем пользователя в группу sudo
usermod -aG sudo $s
#Обновляем систему
sudo apt-get update
sudo apt-get upgrade
#Ставим  нужные компоненты для докер
sudo apt-get install apt-transport-https
sudo apt-get install ca-certificates
sudo apt-get install curl
sudo apt-get install gnupg
sudo apt-get install gpg
sudo apt-get install lsb-releas
#Добавляем ключ GPG
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
#Устанавливаем докер через скрипт
curl -fsSL https://get.docker.com -o get-docker.sh
 sudo sh get-docker.sh
#Добавляем пользователя в группу docker
usermod -aG docker $d
