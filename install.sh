#!/bin/bash

# Переход в корневую директорию
cd /

# Обновление системы
apt update && apt full-upgrade -y

# Установка необходимых пакетов
apt install docker.io docker-compose git curl bash openssl -y

# Клонирование репозитория
git clone https://github.com/0x3654/nginx-3x-ui-subscription-proxy .

# Генерация SSL сертификатов
openssl req -x509 -newkey rsa:4096 -nodes -sha256 -keyout private.key -out public.key -days 3650 -subj "/CN=APP"


# Запуск docker-compose в директории /3x-ui/
cd /3x-ui/ && docker-compose up -d

# Установка WARP proxy
bash <(curl -sSL https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh) 