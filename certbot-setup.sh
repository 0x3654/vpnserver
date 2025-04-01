#!/bin/bash

# Проверка наличия certbot
if ! command -v certbot &> /dev/null; then
    echo "Ошибка: certbot не установлен"
    echo "Установите certbot командой:"
    echo "sudo apt update && sudo apt install certbot"
    exit 1
fi

# Запрос домена
read -p "Введите ваш домен (например, example.com): " DOMAIN

# Проверка доступности домена
if ! ping -c 1 $DOMAIN &> /dev/null; then
    echo "Ошибка: Домен $DOMAIN недоступен. Убедитесь, что DNS записи настроены правильно."
    exit 1
fi

# Создание директорий для сертификатов
mkdir -p /etc/nginx/ssl

# Получение сертификата в standalone режиме
echo "Получение SSL сертификата для домена $DOMAIN..."
certbot certonly --standalone \
    --config-dir ./3x-ui/cert/ \
    --work-dir ./3x-ui/cert/ \
    -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

# Проверка успешности получения сертификата
if [ -f "./3x-ui/cert/live/$DOMAIN/fullchain.pem" ]; then
    echo "Сертификат успешно получен!"
    
    # Создание символических ссылок
    echo "Создание символических ссылок..."
    ln -sf $(pwd)/3x-ui/cert/live/$DOMAIN/fullchain.pem $(pwd)/3x-ui/fullchain.pem
    ln -sf $(pwd)/3x-ui/cert/live/$DOMAIN/privkey.pem $(pwd)/3x-ui/privkey.pem
    
    echo "Настройка завершена успешно!"
else
    echo "Ошибка при получении сертификата"
    docker start nginx_proxy_sub 3x-ui 2>/dev/null || true
    exit 1
fi
echo "-----------------------------------------------------------------------"
echo "Сертификаты:"
ls $(pwd)/3x-ui/*.pem