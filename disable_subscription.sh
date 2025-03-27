#!/bin/bash

# Проверка и установка sqlite3
if ! command -v sqlite3 &> /dev/null; then
    echo "=== Установка sqlite3 ==="
    apt-get update && apt-get install -y sqlite3
fi

# Проверяем наличие базы данных
if [ ! -f "/xray-server/3x-ui/db/x-ui.db" ]; then
    echo "ОШИБКА: База данных не найдена в /xray-server/3x-ui/db/x-ui.db"
    exit 1
fi

cd /xray-server/3x-ui
docker-compose down

# Создаем резервную копию базы данных
echo "=== Создание резервной копии базы данных ==="
cp /xray-server/3x-ui/db/x-ui.db /xray-server/3x-ui/db/x-ui.db.backup

# Отключаем подписку и устанавливаем порт 2000
echo "=== Обновление настроек подписки ==="
sqlite3 /xray-server/3x-ui/db/x-ui.db << EOF
UPDATE settings SET value = 'false' WHERE key = 'subEnable';
UPDATE settings SET value = '2000' WHERE key = 'subPort';
EOF

# Проверяем успешность выполнения
if [ $? -eq 0 ]; then
    echo "=== Настройки успешно обновлены ==="
    echo "Подписка отключена"
    echo "Порт подписки установлен на 2000"
else
    echo "ОШИБКА: Не удалось обновить настройки"
    echo "Восстанавливаем базу из резервной копии..."
    cp /xray-server/3x-ui/db/x-ui.db.backup /xray-server/3x-ui/db/x-ui.db
    exit 1
fi

# Перезапускаем контейнер для применения изменений
echo "=== Перезапуск контейнера ==="
cd /xray-server/3x-ui
docker-compose up -d
cd /

echo "=== Готово! ===" 