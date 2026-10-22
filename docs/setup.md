# Подготовка и запуск

[На главную](../README.md) · [Все сервисы](README.md) · [Диаграммы](architecture.md)

## Получение исходников

Понадобятся Git, Docker Engine и Docker Compose v2:

```bash
git clone https://github.com/Weit145/microservices_site.git
cd microservices_site
git submodule update --init --recursive
git submodule status --recursive
```

Если репозиторий уже клонирован, выполните последние две команды из его корня. Подмодули должны загрузиться до сборки Docker. Их URL перечислены в [.gitmodules](../.gitmodules); [каталог сервисов](README.md) доступен и без загрузки исходников.

### Недоступные коммиты подмодулей

При проверке текущего checkout сервер Git сообщил `not our ref` для Gateway (`34e3408628648ebcfbabd605e20252359a04ae69`) и вложенного `auth-service/proto` (`9b8c89c9afb816f510e1a542aa9ee1bbe393b715`). Из-за этого инициализация прерывается и сборку всей платформы нельзя считать воспроизводимой.

Такая ошибка означает, что сервер не отдаёт закреплённый коммит. Автору репозитория нужно восстановить его из сохранившегося клона либо отдельно выбрать и проверить совместимые версии сервисов и контрактов. Обновление на `--remote` меняет версии и требует самостоятельной проверки; это не шаг обычного запуска. В рамках обновления документации ссылки на коммиты не меняются.

## Переменные окружения

Compose ожидает локальные файлы `.env` в каталогах `auth-service`, `user-service`, `post-service`, `task-service` и `admin-service`. Создайте их после загрузки подмодулей и сверьте настройки с конфигурацией выбранной версии каждого сервиса. Реальные пароли и ключи в Git не добавляйте.

| Файл | Основные переменные для Docker-сети |
| --- | --- |
| `auth-service/.env` | `DB_URL=postgresql+asyncpg://postgres:postgres@postgres_auth:5432/auth_db`, `SECRET_KEY`, `ALGORITHM=HS256`, `KAFKA_BOOTSTRAP_SERVERS=kafka:9092` |
| `user-service/.env` | `DB_URL=postgresql+asyncpg://postgres:postgres@postgres_user:5432/user_db`, `KAFKA_BOOTSTRAP_SERVERS=kafka:9092` |
| `post-service/.env` | `DB_URL=postgresql+asyncpg://postgres:postgres@postgres_post:5432/post_db`, `KAFKA_BOOTSTRAP_SERVERS=kafka:9092` |
| `task-service/.env` | `CELERY_BROKER=pyamqp://guest:guest@rabbitmq:5672//`, `KAFKA_BOOTSTRAP_SERVERS=kafka:9092`, `GOOGLE_USER`, `GOOGLE_APP_PASSWORD` |
| `admin-service/.env` | `KAFKA_BOOTSTRAP_SERVERS=kafka:9092` |

`postgres:postgres` и `guest:guest` — значения из текущего Compose. Для `SECRET_KEY` задайте собственный случайный ключ. Настройки времени жизни токенов перечислены в [Auth README](auth-service/README.md).

У `celery` нет `env_file`: ему переданы только `CELERY_BROKER` и `CELERY_RESULT_BACKEND`. Каталог Task смонтирован в `/app`, поэтому `load_dotenv()` может читать `/app/.env`. Для отправки почты worker должен получить `GOOGLE_USER` и `GOOGLE_APP_PASSWORD`; проверьте это при настройке окружения.

## Домен и сертификаты

Текущий [Nginx](../nginx/nginx.conf) настроен на `kload.ru` и `www.kload.ru`. Запрос на `http://localhost` перенаправится на `https://kload.ru`, поэтому это не адрес локального frontend.

Для запуска существующей конфигурации требуются:

- `nginx/certs/live/kload.ru/fullchain.pem` и `privkey.pem`, включая цели символьных ссылок в `nginx/certs/archive`, если сертификаты выданы Certbot;
- `nginx/ssl/dummy.crt` и `dummy.key` для HTTPS-сервера по умолчанию;
- `nginx/certbot/www` для ACME challenge;
- DNS домена, указывающий на сервер, и доступные порты 80/443.

Выпуск сертификатов необходимо подготовить до запуска Nginx: контейнер Certbot в этом Compose зависит от Nginx, а Nginx без сертификатов не запустится. Отдельного режима локального frontend без TLS текущая конфигурация не содержит. Письма подтверждения также содержат адрес `https://kload.ru/confirm/`.

## Запуск и проверка

После загрузки исходников и подготовки окружения:

```bash
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 nginx gateway auth-service user-service post-service task-service celery
```

`config --quiet` проверяет структуру Compose и наличие файлов окружения, но не готовность приложения, корректность секретов или сертификатов. Не запускайте сборку, если загрузка подмодулей завершилась ошибкой.

```bash
curl --fail http://localhost:8000/openapi.json
docker compose exec nginx nginx -t
```

Gateway доступен отдельно на порту 8000. Nginx проксирует только `/api/` в Gateway, поэтому Swagger открывается через прямой локальный адрес, а не через `https://kload.ru/docs`.

## Адреса и порты

| Компонент | Внутри Docker-сети | С хоста / из браузера |
| --- | --- | --- |
| Nginx / сайт | `nginx:80`, `nginx:443` | [https://kload.ru](https://kload.ru), при настроенном развёртывании |
| Frontend | `frontend:80` | Через Nginx; отдельный порт не опубликован |
| Gateway | `gateway:8000` | [Swagger](http://localhost:8000/docs), [OpenAPI](http://localhost:8000/openapi.json) |
| Auth | `auth-service:50051`, gRPC | Не опубликован |
| User | `user-service:50053`, gRPC для Gateway; `50055` для Post | Не опубликованы; `50055` указан в реализации, не в `expose` |
| Post | `post-service:50054`, gRPC | Не опубликован |
| Admin | `admin-service:50056`, gRPC | Не опубликован |
| Task | Фоновый обработчик Kafka | HTTP/gRPC API нет; `expose: 50052` в Compose не создаёт API |
| Celery | Worker очереди RabbitMQ | Веб-интерфейса нет |
| PostgreSQL Auth | `postgres_auth:5432` | `localhost:5432`, PostgreSQL-клиент |
| PostgreSQL User | `postgres_user:5432` | `localhost:5433`, PostgreSQL-клиент |
| PostgreSQL Post | `postgres_post:5432` | `localhost:5434`, PostgreSQL-клиент |
| Redis | `redis:6379` | `localhost:6379`, Redis-клиент |
| Kafka | `kafka:9092` | Не опубликован; команды выполняются в контейнере |
| RabbitMQ | `rabbitmq:5672`; management `rabbitmq:15672` | Не опубликованы, в том числе management UI |

`expose` описывает внутренние порты и не публикует их на хост. Имена контейнеров разрешаются внутри Docker-сети, а не в браузере на компьютере.

## Обслуживание

```bash
# Пересборка конкретного сервиса
docker compose up -d --build gateway

# Миграции, если требуется выполнить вручную
docker compose exec auth-service poetry run alembic upgrade head
docker compose exec user-service poetry run alembic upgrade head
docker compose exec post-service poetry run alembic upgrade head

# Просмотр событий
docker compose exec kafka kafka-console-consumer \
  --bootstrap-server kafka:9092 --topic registration --from-beginning

# Проверка и перечитывание Nginx после обновления сертификатов
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload

# Остановка без удаления томов данных
docker compose down
```

Хук [renew-hook.sh](../nginx/renew-hook.sh) вызывает `/usr/bin/docker`. В образе `certbot/certbot` Docker CLI и подключение к Docker daemon текущим Compose не предусмотрены, поэтому автоматический reload Nginx требует отдельной настройки. Команды выше позволяют выполнить его с хоста.
