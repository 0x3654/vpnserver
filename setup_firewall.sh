#!/bin/bash
# Получаем порт панели из базы данных
if [ -f "/xray-server/3x-ui/db/x-ui.db" ]; then
    PANEL_PORT=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT value FROM settings WHERE key = 'webPort';")
    if [ -n "$PANEL_PORT" ]; then
        echo "Найден порт панели: $PANEL_PORT"
        ufw allow $PANEL_PORT/tcp
    else
        echo "Внимание: Не удалось получить порт панели из базы данных"
        exit 1
    fi
else
    echo "ОШИБКА: База данных не найдена в /xray-server/3x-ui/db/x-ui.db"
    exit 1
fi
# Разрешаем SSH
ufw allow 22/tcp 
# Разрешаем порт для VLESS/XTLS Reality
ufw allow 443/tcp 
# Разрешаем порт для CDN
ufw allow 2053/tcp
# Получаем порт beszel monitoring из docker-compose.yaml
ufw allow 45876/tcp
# Включаем файрвол
ufw --force enable

# Показываем статус файрвола
echo "=== Статус файрвола ==="
ufw status 