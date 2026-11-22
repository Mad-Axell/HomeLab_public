# cadvisor

## Русский

Развертывает cAdvisor как проект Docker Compose v2 на хосте с уже установленным Docker и публикует метрики контейнеров (CPU, память, сеть, файловые системы) на порту 8080 для сбора Prometheus. Настройка scrape-заданий Prometheus выполняется ролью `prometheus` и не входит в задачи этой роли.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Deploys cAdvisor as a Docker Compose v2 project on a host with Docker already installed and exposes per-container metrics (CPU, memory, network, filesystems) on port 8080 for Prometheus scraping. Prometheus scrape jobs are configured by the `prometheus` role and are out of this role's scope.

Full documentation: [README_ENG.md](README_ENG.md)
