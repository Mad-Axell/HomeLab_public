# frigate

Ansible role for installing and configuring Frigate NVR (Network Video Recorder) in a Docker container.

## Description

This role automates the deployment of Frigate NVR - a video surveillance system with machine learning-based object detection. The role creates necessary directories, generates Docker Compose and Frigate configuration files from templates, and runs the service in a Docker container. The role supports integration with Google Coral EDGE TPU for object detection acceleration, go2rtc configuration for video streaming, and configuration of multiple cameras with different roles (recording, detection).

## Quick Start

```yaml
---
- name: Install Frigate NVR
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
  roles:
    - docker
    - coral-edge-tpu  # optional
    - frigate
```

## Requirements

- Ansible 2.12 or higher
- Python 3.9 or higher
- Debian family distribution (Debian, Ubuntu, Pop!_OS, Linux Mint)
- Docker and Docker Compose installed (recommended: use `docker` role)
- Root or sudo access
- Internet connectivity for Docker image download

## Dependencies

- `docker` role (recommended for Docker and Docker Compose installation)
- `coral-edge-tpu` role (optional, for Coral EDGE TPU support)

## Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `frigate_go2rtc_rtsp_user` | string | Username for go2rtc RTSP streams |
| `frigate_go2rtc_rtsp_pswd` | string | Password for go2rtc RTSP streams |
| `frigate_camera_user` | string | Username for IP camera access |
| `frigate_camera_pswd` | string | Password for IP camera access |

## Documentation

For complete documentation, see:

- **[README_eng.md](README_eng.md)** - Full English documentation
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

