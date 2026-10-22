# Архитектура

[На главную](../README.md) · [Все сервисы](README.md) · [Запуск](setup.md)

Схемы описывают существующие связи платформы. Основной README показывает состав системы; здесь приведены отдельные сценарии. Mermaid отображается на GitHub, исходная картинка доступна [отдельно](architecture.png).

## Запрос публикаций

```mermaid
sequenceDiagram
    actor Browser as Браузер
    participant Nginx
    participant Gateway
    participant Redis
    participant Post as Post Service
    participant PostDB as PostgreSQL · post_db
    participant User as User Service
    participant UserDB as PostgreSQL · user_db
    Browser->>Nginx: GET /api/post/group/
    Nginx->>Gateway: HTTP /api/post/group/
    Gateway->>Redis: Проверка лимита запросов
    alt Лимит превышен
        Gateway-->>Browser: HTTP 429
    else Запрос разрешён
        Gateway->>Post: gRPC · получение постов
        Post->>PostDB: Чтение публикаций
        Post->>User: gRPC · данные авторов, порт 50055
        User->>UserDB: Чтение профилей
        User-->>Post: Данные авторов
        Post-->>Gateway: Публикации
        Gateway-->>Nginx: JSON
        Nginx-->>Browser: HTTP-ответ
    end
```

## Регистрация и подтверждение почты

```mermaid
sequenceDiagram
    actor Visitor as Пользователь
    participant Gateway
    participant Auth as Auth Service
    participant Kafka
    participant Task as Task Service
    participant Rabbit as RabbitMQ
    participant Celery as Celery worker
    participant SMTP
    participant User as User Service
    Visitor->>Gateway: Регистрация
    Gateway->>Auth: gRPC · CreateUser
    Auth->>Auth: Сохранение неактивного пользователя
    Auth->>Kafka: auth · данные для письма
    Kafka->>Task: Событие auth
    Task->>Rabbit: Задачи письма и отложенной проверки
    Rabbit->>Celery: Выполнение задачи
    Celery->>SMTP: Письмо с токеном подтверждения
    SMTP-->>Visitor: Ссылка на kload.ru/confirm/
    Visitor->>Gateway: Подтверждение регистрации
    Gateway->>Auth: gRPC · RegistrationUser
    Auth->>Auth: Активация пользователя
    Auth->>Kafka: registration · создание профиля
    Kafka->>User: Событие registration
    User->>User: Сохранение профиля
    Note over Celery,Auth: Отложенная задача публикует check_verified через Kafka
```

Названия `auth` и `registration` отражают реализацию: Task читает `auth`, User читает `registration`. Создание профиля происходит асинхронно после подтверждения почты.

## Административные события

```mermaid
flowchart LR
    Gateway[Gateway] -->|gRPC| Admin[Admin Service]
    Admin -->|admin_ban_user| Kafka[Kafka]
    Admin -->|admin_delete_user| Kafka
    Admin -->|admin_delete_post| Kafka
    Kafka -->|admin_ban_user, admin_delete_user| Auth[Auth Service]
    Kafka -->|admin_delete_user| User[User Service]
    Kafka -->|admin_delete_post| Post[Post Service]
    User -->|delete| Kafka
    Kafka -->|delete| Auth
    Kafka -->|delete| Post
```

## Границы компонентов

HTTP API предоставляет Gateway. Nginx отдаёт frontend через `/` и проксирует `/api/` в Gateway. Backend-сервисы принимают gRPC внутри Docker-сети `microservices_net`; Task работает через брокеры сообщений. Redis используется Gateway для ограничения частоты запросов.

Auth, User и Post используют отдельные PostgreSQL-базы. Для Admin и Task отдельные базы в Compose не заданы. RabbitMQ передаёт задачи Celery; Kafka передаёт события между сервисами. Proto содержит контракты, отдельный контейнер для него не запускается.

Часть закреплённых коммитов недоступна в удалённых репозиториях. Связи сверены с Compose и доступными исходниками, но это не подтверждает совместимость всех закреплённых версий. [Ограничения запуска](setup.md#недоступные-коммиты-подмодулей).
