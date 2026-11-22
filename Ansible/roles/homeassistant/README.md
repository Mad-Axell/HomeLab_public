# homeassistant

## Русский

Разворачивает Home Assistant Container как проект Docker Compose v2 на выделенном SBC-хосте с уже установленным Docker: каталоги, `compose.yml` с томом `/config`, сетевым режимом host или публикацией порта 8123 и пробросом устройств. Onboarding, интеграции и MQTT к центральному Mosquitto настраиваются в веб-интерфейсе и не входят в задачи роли.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Deploys Home Assistant Container as a Docker Compose v2 project on a dedicated SBC host with Docker already installed: directories, `compose.yml` with a `/config` volume, host network mode or port 8123 publishing, and device passthrough. Onboarding, integrations, and MQTT to the central Mosquitto are configured in the web UI and are out of the role scope.

Full documentation: [README_ENG.md](README_ENG.md)
