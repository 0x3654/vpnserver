#!/bin/bash

# Проверяем наличие базы данных
if [ -f "/xray-server/3x-ui/db/x-ui.db" ]; then
    # Получаем порт панели
    PANEL_PORT=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT value FROM settings WHERE key = 'webPort';")
    if [ -n "$PANEL_PORT" ]; then
        echo "Найден порт панели: $PANEL_PORT"
        ufw allow $PANEL_PORT/tcp
    else
        echo "Внимание: Не удалось получить порт панели из базы данных"
        exit 1
    fi

    # Получаем порт подписки
    SUB_PORT=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT value FROM settings WHERE key = 'subPort';")
    if [ -n "$SUB_PORT" ]; then
        echo "Найден порт подписки: $SUB_PORT"
        ufw allow $SUB_PORT/tcp
    else
        echo "Внимание: Не удалось получить порт подписки из базы данных"
    fi
else
    echo "ОШИБКА: База данных не найдена в /xray-server/3x-ui/db/x-ui.db"
    exit 1
fi

#порт нужен для обновления сертификата через certbot
ufw allow 80/tcp
# Разрешаем SSH
ufw allow 22/tcp 
# Разрешаем порт для VLESS/XTLS Reality
ufw allow 443/tcp 
# Разрешаем порт для CDN
ufw allow 2053/tcp
# Получаем порт beszel monitoring из docker-compose.yaml
BESZEL_PORT=$(grep "LISTEN:" beszel-agent/docker-compose.yaml | awk '{print $2}')
if [ -n "$BESZEL_PORT" ]; then
    echo "Найден порт beszel monitoring: $BESZEL_PORT"
    ufw allow $BESZEL_PORT/tcp
else
    echo "Внимание: Не удалось найти порт beszel monitoring в docker-compose.yaml"
fi
# Включаем файрвол
ufw --force enable

# Показываем статус файрвола
echo "=== Статус файрвола ==="
ufw status 