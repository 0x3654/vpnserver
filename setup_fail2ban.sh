#!/bin/bash

# Проверка на root
if [ "$EUID" -ne 0 ]; then 
    echo "Пожалуйста, запустите скрипт от имени root"
    exit 1
fi

# Установка fail2ban
echo "Установка fail2ban..."
apt update
apt install -y fail2ban whois

#TODO #ИСПРАВИТЬ
# ip server 
# email

#TODO

# Создание локальной конфигурации
echo "Настройка конфигурации fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOL'
[DEFAULT]
# Глобальные настройки, применяемые ко всем jails
ignoreip = 127.0.0.1/8 103.240.146.34 216.9.224.176 109.196.164.162 5.253.62.110 
hantama = 1d
bantime = 1d
findtime = 1h
maxretry = 1
destemail = edger.viewing07@icloud.com
sender = fail2ban@server.local
mta = mail
action = %(action_mwl)s
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
backend = systemd
EOL

# Создание дополнительной конфигурации для systemd бэкенда
cat > /etc/fail2ban/jail.d/00-systemd.conf << 'EOL'
[DEFAULT]
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd
# Пустой logpath, так как journalctl используется автоматически
logpath =
EOL

# активация fail2ban
systemctl enable fail2ban
# остановим сервис fail2ban
systemctl stop fail2ban
#включение оповещений в телеграм
cp -f $(pwd)/fail2ban/telegram.conf /etc/fail2ban/action.d/telegram.conf

# копироавние конфигурации fail2ban
cp -f $(pwd)/fail2ban/jail.conf /etc/fail2ban/jail.conf

# Копирование скрипта оповещений и настройка прав
mkdir /etc/fail2ban/scripts
cp  -f $(pwd)/fail2ban/send_telegram_notif.sh /etc/fail2ban/scripts/send_telegram_notif.sh
chmod +x /etc/fail2ban/scripts/send_telegram_notif.sh

# Получение токена и ID чата из 3x-ui и обновление в скрипте
if [ -f "/xray-server/3x-ui/db/x-ui.db" ]; then
    echo "Получение данных Telegram из 3x-ui..."
    tg_bot_token=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT value FROM settings WHERE key='tgBotToken';")
    tg_chat_id=$(sqlite3 /xray-server/3x-ui/db/x-ui.db "SELECT value FROM settings WHERE key='tgBotChatId';")
    
    if [ ! -z "$tg_bot_token" ] && [ ! -z "$tg_chat_id" ]; then
        echo "Обновление данных Telegram в скрипте оповещений..."
        sed -i "s/telegramBotToken='YOUR_BOT_TOKEN'/telegramBotToken='$tg_bot_token'/" /etc/fail2ban/scripts/send_telegram_notif.sh
        sed -i "s/telegramChatID='YOUR_CHAT_ID'/telegramChatID='$tg_chat_id'/" /etc/fail2ban/scripts/send_telegram_notif.sh
        echo "Данные Telegram успешно обновлены"
    else
        echo "ВНИМАНИЕ: Не удалось получить данные Telegram из 3x-ui"
    fi
else
    echo "ВНИМАНИЕ: База данных 3x-ui не найдена"
fi

chmod +x /etc/fail2ban/scripts/send_telegram_notif.sh

systemctl restart fail2ban

# Вывод информации
echo "
Установка и настройка fail2ban завершена!
Текущие настройки:
- Время бана: 1 сутки
- Время поиска нарушений: 1 час
- Максимальное количество попыток: 1

Для просмотра заблокированных IP используйте команду:
fail2ban-client status

Для разблокировки IP используйте команду:
fail2ban-client set [jail] unbanip [IP]
"