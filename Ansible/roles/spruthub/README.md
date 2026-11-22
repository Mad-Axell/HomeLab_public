# spruthub

## Русский

Разворачивает Sprut.hub как проект Docker Compose v2 на выделенном SBC-хосте с уже установленным Docker: каталоги, `compose.yml` с пробросом Zigbee/Z-Wave устройств и контейнер в требуемом состоянии. Образ вендора задается через `spruthub_image`; настройки внутри продукта, включая MQTT к центральному Mosquitto, выполняются в его веб-интерфейсе и не входят в задачи роли.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Deploys Sprut.hub as a Docker Compose v2 project on a dedicated SBC host with Docker already installed: directories, `compose.yml` with Zigbee/Z-Wave device passthrough, and the container in the desired state. The vendor image is supplied through `spruthub_image`; in-product configuration, including MQTT to the central Mosquitto, is done in its web UI and is out of the role scope.

Full documentation: [README_ENG.md](README_ENG.md)
