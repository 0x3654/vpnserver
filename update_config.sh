#!/bin/bash

# Проверка и установка sqlite3
if ! command -v sqlite3 &> /dev/null; then
    echo "=== Установка sqlite3 ==="
    apt-get update && apt-get install -y sqlite3
fi

# Функция для генерации случайного порта (от 10000 до 65535)
generate_random_port() {
    echo $((RANDOM % 55535 + 10000))
}

# Функция для генерации случайного пути (8 символов)
generate_random_path() {
    openssl rand -base64 6 | tr -d '/+=' | head -c 8
}

# Функция для генерации Reality ключей
generate_reality_keys() {
    # Генерация приватного ключа
    private_key=$(openssl rand -base64 32)
    # Генерация публичного ключа
    public_key=$(echo -n "$private_key" | openssl dgst -sha256 -binary | openssl base64 -A)
    # Генерация ShortID (8 символов hex)
    short_id=$(openssl rand -hex 4)
    
    echo "$private_key|$public_key|$short_id"
}

# Останавливаем контейнер перед изменением базы
echo "=== Остановка контейнера ==="
cd /xray-server/3x-ui
docker-compose down

# Проверяем наличие базы данных
if [ ! -f "db/x-ui.db" ]; then
    echo "ОШИБКА: База данных не найдена в db/x-ui.db"
    echo "Восстанавливаем контейнер..."
    docker-compose up -d
    exit 1
fi

# Создаем резервную копию базы данных
echo "=== Создание резервной копии базы данных ==="
cp db/x-ui.db db/x-ui.db.backup

# Проверяем успешность выполнения SQL-запросов
check_sql_error() {
    if [ $? -ne 0 ]; then
        echo "ОШИБКА: Ошибка при выполнении SQL-запроса"
        echo "Восстанавливаем базу из резервной копии..."
        cp db/x-ui.db.backup db/x-ui.db
        docker-compose up -d
        exit 1
    fi
}

# Получаем внешний IP
EXTERNAL_IP=$(curl -s ifconfig.me)

# Генерируем новые значения
WEB_PORT=$(generate_random_port)
BASE_PATH=$(generate_random_path)
REALITY_KEYS=$(generate_reality_keys)
PRIVATE_KEY=$(echo $REALITY_KEYS | cut -d'|' -f1)
PUBLIC_KEY=$(echo $REALITY_KEYS | cut -d'|' -f2)
SHORT_ID=$(echo $REALITY_KEYS | cut -d'|' -f3)

# Сохраняем ID клиентов
CLIENT_IDS=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT json_extract(value, '$.id') FROM inbounds, json_each(json_extract(inbounds.settings, '$.clients')) WHERE inbounds.id = 1;" | tr '\n' '|')

# Обновляем настройки в базе
echo "=== Обновление настроек в базе данных ==="
sqlite3 /xray-server/3x-ui/db/x-ui.db << EOF
UPDATE settings SET value = '$WEB_PORT' WHERE key = 'webPort';
UPDATE settings SET value = '$BASE_PATH' WHERE key = 'webBasePath';
EOF
check_sql_error

sqlite3 /xray-server/3x-ui/db/x-ui.db << EOF
UPDATE inbounds SET 
    listen = '$EXTERNAL_IP',
    settings = json_replace(
        settings,
        '$.clients[0].id', '$(echo $CLIENT_IDS | cut -d'|' -f1)',
        '$.clients[1].id', '$(echo $CLIENT_IDS | cut -d'|' -f2)',
        '$.clients[2].id', '$(echo $CLIENT_IDS | cut -d'|' -f3)',
        '$.clients[3].id', '$(echo $CLIENT_IDS | cut -d'|' -f4)'
    ),
    streamSettings = json_replace(
        streamSettings,
        '$.realitySettings.privateKey', '$PRIVATE_KEY',
        '$.realitySettings.publicKey', '$PUBLIC_KEY',
        '$.realitySettings.shortIds[0]', '$SHORT_ID'
    )
WHERE id = 1;
EOF
check_sql_error

# Выводим информацию
echo "=== Новые настройки ==="
echo "URL панели: https://$EXTERNAL_IP:$WEB_PORT/$BASE_PATH"
echo "Публичный ключ Reality: $PUBLIC_KEY"
echo "Приватный ключ Reality: $PRIVATE_KEY"
echo "ShortID: $SHORT_ID"
echo "=== Сохраненные ID клиентов ==="
echo $CLIENT_IDS | tr '|' '\n'

# Запускаем контейнер
echo "=== Запуск контейнера ==="
cd /xray-server/3x-ui
docker-compose up -d
cd ..

echo "=== Готово! ==="
echo "Панель будет доступна через несколько секунд по новому URL"