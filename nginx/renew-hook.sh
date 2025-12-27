#!/bin/sh

# Путь к docker на хосте (обычно так)
DOCKER="/usr/bin/docker"

# Имя контейнера nginx (точно как в docker-compose.yml)
CONTAINER_NAME="nginx"

echo "Certbot renew hook: пытаемся перезагрузить nginx..." >&2

# Проверяем, что контейнер существует и запущен
if ! $DOCKER ps --filter "name=^/${CONTAINER_NAME}$" --filter "status=running" -q | grep -q .; then
    echo "Ошибка: контейнер $CONTAINER_NAME не запущен или не существует" >&2
    exit 1
fi

# Выполняем reload
if $DOCKER exec $CONTAINER_NAME nginx -s reload; then
    echo "Nginx успешно перезагружен после обновления сертификатов" >&2
    exit 0
else
    echo "Ошибка при перезагрузке nginx!" >&2
    exit 1
fi