#!/bin/bash
#выполнить перед этим 
#wget https://raw.githubusercontent.com/0x3654/xray-server/main/start.sh -O start.sh && chmod +x start.sh && bash /start.sh

# Переход в корневую директорию
cd /
# Обновление системыi
echo "Обновим систему и установим необходимые пакеты"
apt update && apt full-upgrade -y && apt install docker.io docker-compose curl bash openssl htop vim sqlite3 certbot -y
echo "Готово!"

# Клонирование репозитория
echo "загрузка файлов из репозитория"
git clone https://github.com/0x3654/xray-server 

# Генерация SSL сертификатов

echo "Создание SSL сертификатов"
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d 

# Запуск docker-compose в директории /3x-ui/
cd /xray-server/3x-ui/ && docker-compose up -

sqlite3 '/xray-server/3x-ui/db/x-ui.db' < import.sql

















