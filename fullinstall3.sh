#!/bin/bash
echo "You are welcomed by Infomaximum"
echo "Вас приветствует компания Infomaximum"
echo "Vas privetstvuet kompaniya Infomaximum"
echo
echo "Thank you for using our product"
echo "Спасибо, что воспользовались нашим продуктом"
echo "Spasibo, chto vospol'zovalis' nashim produktom"
echo
echo "This script is designed to install Docker and ClickHouse"
echo "Данный скрипт предназначен для установки Docker и ClickHouse"
echo "Dannyj skript prednaznachen dlya ustanovki Docker i ClickHouse"
read -n 1 -p "Start installation? (y/[a]): " AMSURE
read m
[ "$AMSURE" = "y" ] || exit
echo ""
sleep 1
echo
echo "Enter:   1 to start installing Docker and ClickHouse"
echo "         2 if Docker is installed "
echo
echo "Введите: 1 для начала установки Docker и ClickHouse"
echo "         2 если Docker установлен"        
echo
echo "Vvedite: 1 dlya nachala ustanovki Docker i ClickHouse"
echo "         2 esli Docker ustanovlen "
read g
if [[ $g = 1 ]]
   then
#Собираем данные по пользователям
echo
echo "Enter an existing user to add to the docker group"
echo "Введите существующего пользователя для добавления в группу docker"
echo "Vvedite sushchestvuyushchego pol'zovatelya dlya dobavleniya v gruppu docker"
read d
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
     else
	 echo
	 echo "Installing ClickHouse"
	 echo "Устанавливаем ClickHouse"
	 echo "Ustanavlivaem ClickHouse"
fi
#Если система закрытая, выше написаный код можно закоментировать или удалить
#Распаковываем архив в директорию пользователя
gunzip infomaximum_clickhouse-20.4.5.36p4.tar.gz
docker load<infomaximum_clickhouse-20.4.5.36p4.tar
#Docker swarm
docker swarm init --advertise-addr 127.0.0.1:2377 --listen-addr 127.0.0.1:2377
#Спрашиваем данные администратора
echo "Enter the DB administrator login"
echo "Введите логин администратора СУБД"
echo "Vvedite login administratora SUBD"
read loginadmin
echo "Enter the password" $loginadmin
echo "Введите пароль" $loginadmin
echo "Vvedite parol'" $loginadmin
read passwdadmin
#Создаем секреты администратора СУБД
echo -n $loginadmin | docker secret create infomaximum_app_user -
echo -n $passwdadmin | sha256sum | awk '{print $1}' | docker secret create infomaximum_app_user_password_hash -
#Спрашиваем данные пользователя
echo "Enter the DB user login"
echo "Введите логин пользователя СУБД"
echo "Vvedite login pol'zovatelya SUBD"
read loginuser
echo "Enter the password" $logiuser
echo "Введите пароль" $logiuser
echo "Vvedite parol'" $logiuser
read passwduser
#Создаем секреты пользователя СУБД
echo -n $loginuser | docker secret create infomaximum_external_user -
echo -n $passwduser | sha256sum | awk '{print $1}' | docker secret create infomaximum_external_user_password_hash -
#Создаем SSL сертификаты 
echo "Enter: 1 to specify the path to your own certificates"
echo "       2 to automatically generate certificates"
echo
echo "Введите: 1 для указания пути до собственных сертификатов"
echo "         2 для автоматической генерации сертификатов"
echo
echo "Vvedite: 1 dlya ukazaniya puti do sobstvennyh sertifikatov"
echo "         2 dlya avtomaticheskoj generacii sertifikatov"
read vybor
echo "Enter the dhparam size in 512, 1024, 2048 or 4096 format"
echo "Введите размер dhparam в формате 512, 1024, 2048 или 4096"
echo "Vvedite razmer dhparam v formate 512, 1024, 2048 ili 4096"
read dh
if [[ $vybor = 1 ]]
    then
	 echo "Enter the full path to crt"
     echo "Введите полный путь до crt"
	 echo "Vvedite polnyj put' do crt"
     read pathcrt
	 echo "Enter the full path to key"
     echo "Введите полный путь до key"
	 echo "Vvedite polnyj put' do key"
     read pathkey
     docker secret create infomaximum_clickhouse.crt $pathcrt
     docker secret create infomaximum_clickhouse.key $pathkey
     openssl dhparam $dh - | docker secret create infomaximum_clickhouse_dhparam.pem -
    else
     if [[ $vybor = 2 ]]
       then
        openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout clickhouse.key -out clickhouse.crt
        docker secret create infomaximum_clickhouse.crt clickhouse.crt
        docker secret create infomaximum_clickhouse.key clickhouse.key
        openssl dhparam $dh - | docker secret create infomaximum_clickhouse_dhparam.pem -
        echo
		echo "Enter the password for the pfx format certificate"
		echo "Введите пароль для сертификата формата pfx"
		echo "Vvedite parol' dlya sertifikata formata pfx"
		echo
        openssl pkcs12 -export -out clickhouse.pfx -inkey clickhouse.key -in clickhouse.crt
       else
echo "Invalid data format"	   
echo "Неверный формат данных"
echo "Nevernyj format dannyh"
fi
fi
#Создаем тома LVM в Docker
docker volume create infomaximum-clickhouse
docker volume create infomaximum-clickhouse-log
#Создаем службу
echo
echo "Wait for the start of the service"
echo "Ожидайте старта службы"
echo "Ozhidajte starta sluzhby"
echo
docker service create --name infomaximum-clickhouse \
--secret infomaximum_app_user \
--secret infomaximum_app_user_password_hash \
--secret infomaximum_external_user \
--secret infomaximum_external_user_password_hash \
--secret infomaximum_clickhouse_dhparam.pem \
--secret infomaximum_clickhouse.crt \
--secret infomaximum_clickhouse.key \
--publish published=8123,target=8123,mode=host \
--mount type=volume,src=infomaximum-clickhouse,target=/var/lib/clickhouse/ \
--mount type=volume,src=infomaximum-clickhouse-log,target=/var/log/clickhouse-server \
--restart-max-attempts 5 \
--restart-condition "on-failure" \
--no-resolve-image \
infomaximum/infomaximum-clickhouse:20.4.5.36p4
#dockerhub.office.infomaximum.com/infomaximum/infomaximum-clickhouse:20.4.5.36p4
