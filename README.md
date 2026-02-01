#  Микросервисный Сайт

Это центральный репозиторий платформы форума с микросервисной архитектурой.

Этот репозиторий **не содержит бизнес-логики сервисов**.
Он описывает:
- общую архитектуру системы;
- состав микросервисов;
- инфраструктуру;
- порядок локального и production-запуска.

Платформа развернута и доступна онлайн:
🔗 https://kload.ru

---

## 🎯 Назначение репозитория

- Оркестрация сервисов через Docker Compose.
- Конфигурация Nginx и сетевого взаимодействия.
- Единая точка входа в систему.
- Документация по архитектуре платформы.

Каждый микросервис разрабатывается и версионируется **в отдельном репозитории**.

---

## 🧱 Архитектура

<p align="center">
  <img src="docs/architecture.png" width="800">
</p>

<p align="center">
  <em>Архитектура микросервисной платформы</em>
</p>

- Микросервисная архитектура.
- Отдельная база данных на сервис (database-per-service).
- HTTP-доступ только через API Gateway.
- Внутреннее взаимодействие между сервисами через gRPC.
- Асинхронные задачи через RabbitMQ + Celery.
- Событийная интеграция через Kafka.

---

## 📦 Сервисы платформы

| Сервис        | Описание                                                                                                | Порт (gRPC/HTTP) | Репозиторий                                          |
|---------------|---------------------------------------------------------------------------------------------------------|------------------|------------------------------------------------------|
| **Auth Service**  | Управляет регистрацией, аутентификацией и JWT. Построен по DDD, активно использует Kafka для событий. | `50051`          | [auth-service](https://github.com/Weit145/auth-service) |
| **User Service**  | Хранит профили. Предоставляет два gRPC API: один для Gateway, другой — для внутренних сервисов.       | `50053`, `50055` | [user-service](https://github.com/Weit145/user-service) |
| **Post Service**  | Управляет постами. Является gRPC-клиентом к User Service для получения данных об авторах.                | `50054`          | [post-service](https://github.com/Weit145/post-service) |
| **Task Service**  | Асинхронный сервис отправки email (через Celery) по событиям из Kafka (например, при регистрации).    | `N/A`            | [task-service](https://github.com/Weit145/task-service) |
| **Gateway**       | Единая точка входа (HTTP → gRPC). Реализует rate-limiting с помощью Redis.                                | `8000`           | [gateway-service](https://github.com/Weit145/gateway) |
| **Admin Service** | Сервис для административных задач. Публикует события о банах/удалениях в Kafka.                      | `50056`          | [admin-service](https://github.com/colosss/admin-service.git) |
| **Frontend**      | Клиентское приложение на React. Реализует продвинутую логику авто-обновления JWT через interceptors.   | `80` (через Nginx) | [kload-frontend](https://github.com/colosss/kload-frontend) |

---

## 💻 Основные технологии

- **Бэкенд:** Python, FastAPI, gRPC, SQLAlchemy, Alembic, Celery, aiokafka.
- **Фронтенд:** React, TypeScript, Vite, React Router DOM, Axios.
- **Базы данных:** PostgreSQL, Redis (для rate limiting).
- **Брокеры сообщений:** Kafka, RabbitMQ.
- **Инфраструктура:** Docker, Docker Compose, Nginx.
- **Контракты API:** Protocol Buffers.

---

## 🐳 Запуск платформы

### Локальная среда

1.  **Установите Docker и Docker Compose:** Убедитесь, что Docker и Docker Compose установлены в вашей системе.
2.  **Клонируйте репозиторий с сабмодулями:**
    ```bash
    git clone --recurse-submodules https://github.com/Weit145/microservices_site.git
    cd microservices_site
    ```
3.  **Запустите платформу:**
    ```bash
    docker-compose up -d --build
    ```
    Эта команда соберет и запустит все сервисы в фоновом режиме.

---

## 🛠️ Полезные команды

### Регенерация gRPC-кода

После изменения `.proto` файлов в сабмодуле `proto`, необходимо пересобрать gRPC-классы для сервисов. Выполните в корневой папке сервиса (например, `auth-service`):
```bash
poetry run python -m grpc_tools.protoc -I proto --python_out=proto --grpc_python_out=proto proto/auth/auth.proto
```

### Миграции базы данных

Для применения миграций к базе данных (например, для `auth-service`):
```bash
docker-compose exec auth-service alembic upgrade head
```

### Просмотр сообщений в Kafka

Для отладки можно прослушать сообщения в определенном топике (например, `registration`):
```bash
docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic registration --from-beginning
```

### Пересборка отдельного сервиса

Если вы внесли изменения только в один сервис (например, `frontend`):
```bash
docker-compose stop frontend
docker-compose build frontend
docker-compose up -d frontend
```

---

## 🤝 Вклад в проект

Если вы хотите внести свой вклад в проект, следуйте этим шагам:

1.  Создайте форк репозитория.
2.  Создайте новую ветку для вашей функции (`git checkout -b feature/AmazingFeature`).
3.  Зафиксируйте ваши изменения (`git commit -m 'Добавлена крутая функция'`).
4.  Отправьте изменения в вашу ветку (`git push origin feature/AmazingFeature`).
5.  Откройте запрос на слияние (Pull Request).

---
