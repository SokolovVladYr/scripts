#!/bin/bash
#Распаковываем архив в директорию пользователя
gunzip infomaximum_clickhouse-20.4.5.36p4.tar.gz
docker load<infomaximum_clickhouse-20.4.5.36p4.tar
#Docker swarm
docker swarm init --advertise-addr 127.0.0.1:2377 --listen-addr 127.0.0.1:2377
#Спрашиваем данные администратора
echo "Введите логин администратора СУБД"
read loginadmin
echo "Введите пароль" $loginadmin
read passwdadmin
#Создаем секреты администратора СУБД
echo -n $loginadmin | docker secret create infomaximum_app_user -
echo -n $passwdadmin | sha256sum | awk '{print $1}' | docker secret create infomaximum_app_user_password_hash -
#Спрашиваем данные пользователя
echo "Введите логин пользователя СУБД"
read loginuser
echo "Введите пароль" $logiuser
read passwduser
#Создаем секреты пользователя СУБД
echo -n $loginuser | docker secret create infomaximum_external_user -
echo -n $passwduser | sha256sum | awk '{print $1}' | docker secret create infomaximum_external_user_password_hash -
#Создаем SSL сертификаты 
echo "Введите: 1 для указания пути до собственных сертификатов"
echo "         2 для автоматической генерации сертификатов"
read vybor
if [[ $vybor = 1 ]]
    then
     echo "Введите путь до crt"
     read pathcrt
     echo "Введите путь до key"
     read pathkey
     docker secret create infomaximum_clickhouse.crt $pathcrt
     docker secret create infomaximum_clickhouse.key $pathkey
     openssl dhparam 4096 - | docker secret create infomaximum_clickhouse_dhparam.pem -
    else
     if [[ $vybor = 2 ]]
       then
        openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout key.key -out cert.crt
        docker secret create infomaximum_clickhouse.crt cert.crt
        docker secret create infomaximum_clickhouse.key key.key
        openssl dhparam 4096 - | docker secret create infomaximum_clickhouse_dhparam.pem -
       else
echo "Неверный формат данных"
fi
fi
#Создаем тома LVM в Docker
docker volume create infomaximum-clickhouse
docker volume create infomaximum-clickhouse-log
#Создаем службу
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
#





