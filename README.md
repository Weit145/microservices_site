# 🧩 Microservices_Site

Центральный репозиторий микросервисной платформы форума.

Данный репозиторий не содержит бизнес-логики сервисов.
Он описывает:
  - общую архитектуру системы;
  - состав микросервисов;
  - инфраструктуру;
  - порядок локального и production-запуска.

Платформа задеплоена и доступна онлайн:
  🔗https://kload.ru

🎯 Назначение репозитория:
  - оркестрация сервисов через Docker Compose;
  - конфигурация Nginx и сетевого взаимодействия;
  - единая точка входа в систему;
  - документация по архитектуре платформы.
Каждый микросервис разрабатывается и версионируется в отдельном репозитории.

## 🧱 Архитектура

  ![Architecture Diagram](/docs/architecture.png)

  - микросервисная архитектура;
  - отдельная база данных на сервис;
  - HTTP-доступ только через Gateway;
  - внутреннее взаимодействие через gRPC;
  - асинхронные задачи через RabbitMQ + Celery;
  - событийная интеграция через Kafka.

## 📦 Сервисы платформы

| Сервис        | Назначение                              |
|--------------|------------------------------------------|
| Auth Service | Аутентификация, JWT, email-подтверждение |
| User Service | Пользовательские профили                 |
| Post Service | Посты и публикации                       | 
| Task Service | Асинхронные задачи                       |
| Gateway      | HTTP → gRPC API Gateway                  | 
| Admin Service| Внутренние админ-задачи                  |
| Frontend     | Веб-интерфейс (React)                    |

## 🗄️ Хранилища данных

  - PostgreSQL (отдельный инстанс на сервис)
  - RabbitMQ — очередь задач
  - Kafka — брокер событий

## 🌐 Точка входа

Nginx является единственным публичным компонентом системы и отвечает за:
  - HTTPS;
  - проксирование запросов;
  - маршрутизацию трафика к frontend и API Gateway.

## 🐳 Запуск платформы

Локально
  - Установите Docker и Docker Compose.
  - Склонируйте данный репозиторий.
  - Выполните команду: docker-compose up -d --build
  После запуска:
    - frontend доступен по /;
    - API доступно через /api;

## 🔗 Репозитории сервисов

  - Auth Service: 🔗 https://github.com/Weit145/auth-service
  - User Service: 🔗 https://github.com/Weit145/user-service
  - Post Service: 🔗 https://github.com/Weit145/post-service
  - Task Service: 🔗 https://github.com/Weit145/task-service
  - Gateway Service: 🔗 https://github.com/Weit145/gateway-service
  - Admin Service: 🔗 https://github.com/Weit145/admin-service
  - Frontend: 🔗 https://github.com/colosss/kload-frontend

## 🧠 Почему такая структура

  - упрощает масштабирование команды;
  - позволяет независимо версионировать сервисы;
  - снижает связанность компонентов;
  - приближает проект к production-подходу.

## 🚀 Что можно добавить или улудшить?

  - observability (Prometheus, Grafana, tracing);
  - CI/CD пайплайны;
  - Тестирование на каждом уровне.