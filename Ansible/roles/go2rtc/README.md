# go2rtc

**RU.** Роль развёртывает go2rtc как отдельный Docker-контейнер: универсальный
шлюз камер (RTSP/WebRTC/MSE/HLS/MJPEG) и единая точка подключения к камерам для
Frigate, Home Assistant и других потребителей. Потоки и учётные данные камер
приходят через `vault_go2rtc_config` из `VARS/secrets.yml`. Полная
документация — `README_RUS.md`.

**EN.** The role deploys go2rtc as a dedicated Docker container: a universal
camera gateway (RTSP/WebRTC/MSE/HLS/MJPEG) acting as the single connection
point to cameras for Frigate, Home Assistant and other consumers. Streams and
camera credentials arrive through `vault_go2rtc_config` from
`VARS/secrets.yml`. Full documentation — `README_ENG.md`.
