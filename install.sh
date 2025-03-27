#!/bin/bash
# Переход в корневую директорию
cd /
# Обновление системы
apt update && apt full-upgrade -y && apt install docker.io docker-compose git curl bash openssl htop -y
# Клонирование репозитория
git clone https://github.com/0x3654/xray-server 
# Генерация SSL сертификатов
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -keyout private.key -out public.key -days 3650
# Запуск docker-compose в директории /3x-ui/
cd /3x-ui/ && docker-compose up -d
# Запуск WARP скрипта с параметрами
./warp_install.sh -y -f