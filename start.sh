#!/bin/bash
# Переход в корневую директорию
cd /
# Обновление системы
apt update && apt full-upgrade -y && apt install docker.io docker-compose curl bash openssl htop vim sqlite3 -y
# Клонирование репозитория
git clone https://github.com/0x3654/xray-server 
# Генерация SSL сертификатов
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -keyout private.key -out public.key -days 3650 -subj "/CN=localhost"
chmod +x /xray-server/update_config.sh
chmod +x /xray-server/3x-ui/warp_install.sh
# Запуск docker-compose в директории /3x-ui/
cd /xray-server/3x-ui/ && docker-compose up -d
# Запуск WARP скрипта с параметрами
./xray-server/warp_install.sh -y -f