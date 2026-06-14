# frigate

Ansible role for installing and configuring Frigate NVR (Network Video Recorder) in a Docker container.

## Description

This role automates the deployment of Frigate NVR - a video surveillance system with machine learning-based object detection. The role creates necessary directories, generates Docker Compose and Frigate configuration files from templates, and runs the service in a Docker container. The role supports integration with Google Coral EDGE TPU for object detection acceleration, go2rtc configuration for video streaming, and configuration of multiple cameras with different roles (recording, detection).

## Requirements

### Control Node Requirements

- Ansible 2.12 or higher
- Python 3.9 or higher

### Managed Node Requirements

- Debian family distribution (Debian, Ubuntu, Pop!_OS, Linux Mint)
- Docker and Docker Compose installed (recommended: use `docker` role)
- Root or sudo access
- Internet connectivity for Docker image download
- Access to USB devices (for Coral EDGE TPU, if used)
- Access to GPU devices (for hardware video acceleration, optional)

### Dependencies

- `docker` role (recommended for Docker and Docker Compose installation)
- `coral-edge-tpu` role (optional, for Coral EDGE TPU support)

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `frigate_go2rtc_rtsp_user` | string | Username for go2rtc RTSP streams |
| `frigate_go2rtc_rtsp_pswd` | string | Password for go2rtc RTSP streams |
| `frigate_camera_user` | string | Username for IP camera access |
| `frigate_camera_pswd` | string | Password for IP camera access |

### Optional Variables

#### Docker Core Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_container_name` | string | `frigate_nvr` | Docker container name |
| `frigate_version` | string | `0.15.1` | Frigate Docker image version (can use `stable` for latest stable version) |
| `frigate_config_version` | string | `0.14` | Frigate configuration version |
| `frigate_shm_size` | string | `512mb` | Shared memory size for container (should be calculated based on number of cameras) |
| `frigate_tmpfs_size` | int | `5000000000` | tmpfs cache size (in bytes, default ~5GB) |
| `frigate_tmpfs_target` | string | `/tmp/cache` | tmpfs mount target inside container |

#### Path and Directory Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_base_dir` | string | `/opt/frigate` | Base directory for Frigate data |
| `frigate_config_dir` | string | `{{ frigate_base_dir }}/config` | Configuration files directory |
| `frigate_clips_dir` | string | `{{ frigate_base_dir }}/cctv_clips` | Clips storage directory |
| `frigate_media_dir` | string | `{{ frigate_base_dir }}/media` | Media files directory |
| `frigate_docker_compose_path` | string | `/opt/docker-compose.yaml` | Docker Compose file path |

#### Port Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_port_go2rtc_web` | int | `1984` | go2rtc web interface port |
| `frigate_port_authenticated` | int | `8971` | Authenticated UI and API port (for reverse proxy) |
| `frigate_port_internal` | int | `5000` | Internal unauthenticated UI and API port (Docker network only) |
| `frigate_port_rtmp` | int | `1935` | RTMP streams port |
| `frigate_port_webrtc_tcp` | int | `8555` | WebRTC over TCP port |
| `frigate_port_webrtc_udp` | int | `8555` | WebRTC over UDP port |
| `frigate_port_rtsp` | int | `8554` | RTSP restreaming port |

#### Device Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_usb_device_host` | string | `/dev/bus/usb` | USB device path on host |
| `frigate_usb_device_container` | string | `/dev/bus/usb` | USB device path in container |
| `frigate_gpu_device` | string | `/dev/dri/renderD128` | GPU device path for hardware acceleration (Intel) |
| `frigate_timezone_host` | string | `/etc/localtime` | Timezone file path on host |
| `frigate_timezone_container` | string | `/etc/localtime` | Timezone file path in container |
| `frigate_coral_device` | string | `usb` | Coral TPU device type: `usb` or `pci` |

#### Docker Volume Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_config_volume_host` | string | `{{ frigate_config_dir }}` | Config directory on host |
| `frigate_config_volume_container` | string | `/config` | Config directory in container |
| `frigate_media_volume_host` | string | `{{ frigate_media_dir }}` | Media directory on host |
| `frigate_media_volume_container` | string | `/media/frigate` | Media directory in container |

#### Detection Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_detector_type` | string | `edgetpu` | Detector type: `edgetpu` (Coral TPU), `cpu` (CPU) |
| `frigate_track_objects` | list | `['person']` | List of objects to track |
| `frigate_alert_labels` | list | `['person']` | List of labels for alerts |
| `frigate_detection_labels` | list | `['person']` | List of labels for detections |

#### Recording Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_record_enabled` | bool | `true` | Enable video recording |
| `frigate_record_expire_interval` | int | `60` | Expire interval in seconds |
| `frigate_record_sync_recordings` | bool | `false` | Sync recordings |
| `frigate_record_retain_days` | int | `1` | Number of days to retain recordings |
| `frigate_record_mode` | string | `all` | Recording mode: `all` (all), `motion` (motion only) |
| `frigate_record_preview_quality` | string | `medium` | Preview quality: `low`, `medium`, `high` |
| `frigate_pre_capture` | int | `7` | Seconds of recording before event |
| `frigate_post_capture` | int | `7` | Seconds of recording after event |
| `frigate_alerts_retain_days` | int | `10` | Number of days to retain alerts |
| `frigate_alerts_retain_mode` | string | `motion` | Alerts retention mode: `all`, `motion` |
| `frigate_detections_retain_days` | int | `10` | Number of days to retain detections |
| `frigate_detections_retain_mode` | string | `motion` | Detections retention mode: `all`, `motion` |

#### Snapshot Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_snapshots_enabled` | bool | `true` | Enable snapshot creation |
| `frigate_snapshots_timestamp` | bool | `true` | Add timestamp to snapshots |
| `frigate_snapshots_bounding_box` | bool | `true` | Show detected object bounding box |
| `frigate_snapshots_crop` | bool | `false` | Crop snapshot to object |
| `frigate_snapshots_clean_copy` | bool | `false` | Create clean copy of snapshot |
| `frigate_snapshots_retain_default` | int | `0` | Default snapshot retention days |
| `frigate_snapshots_retain_objects` | dict | `{'person': 0}` | Snapshot retention days by object type |

#### UI Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_ui_timezone` | string | `Europe/Moscow` | Timezone for UI |
| `frigate_ui_time_format` | string | `24hour` | Time format: `12hour` or `24hour` |
| `frigate_ui_date_style` | string | `medium` | Date display style |
| `frigate_ui_time_style` | string | `medium` | Time display style |
| `frigate_ui_strftime_fmt` | string | `%Y-%m-%d %H:%M:%S` | strftime format string |

#### Birdseye Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_birdseye_enabled` | bool | `false` | Enable Birdseye view (overview of all cameras) |
| `frigate_birdseye_width` | int | `1280` | Birdseye width |
| `frigate_birdseye_height` | int | `720` | Birdseye height |
| `frigate_birdseye_quality` | int | `15` | Birdseye quality (1-31, lower = better quality) |
| `frigate_birdseye_mode` | string | `motion` | Birdseye mode: `motion`, `continuous`, `objects` |

#### MQTT Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_mqtt_enabled` | bool | `false` | Enable MQTT integration |

#### Camera Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_cameras` | dict | `{}` | Dictionary of camera configurations (see examples below) |
| `frigate_go2rtc_host` | string | `10.30.150.5` | go2rtc host IP address (usually localhost or container IP) |
| `frigate_camera_port` | int | `554` | IP camera RTSP port |
| `frigate_camera_channel` | int | `1` | Camera channel number |
| `frigate_camera_subtype_main` | int | `0` | Camera main stream subtype |
| `frigate_camera_subtype_sub` | int | `1` | Camera sub stream subtype |

#### go2rtc Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_go2rtc_rtsp_listen` | string | `:8554` | go2rtc RTSP listen address |

#### FFmpeg Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_ffmpeg_output_args_record` | string | `preset-record-generic-audio-copy` | FFmpeg output args for recording |
| `frigate_ffmpeg_input_args` | string | `preset-rtsp-restream-low-latency` | FFmpeg input args |
| `frigate_ffmpeg_retry_interval` | int | `10` | FFmpeg retry interval in seconds |

#### Reboot Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `frigate_reboot_enabled` | bool | `true` | Perform LXC container reboot before installation |
| `frigate_reboot_timeout` | int | `3600` | Reboot wait timeout (in seconds) |
| `frigate_reboot_msg` | string | `Rebooting LXC in 5 seconds` | Reboot message |

## Example Playbook

### Basic Usage

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

### Configuration with Custom Parameters

```yaml
---
- name: Install Frigate with settings
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    
    frigate_version: "stable"
    frigate_shm_size: "1gb"
    frigate_tmpfs_size: 10000000000  # 10GB
    
    frigate_record_retain_days: 7
    frigate_alerts_retain_days: 30
    
    frigate_track_objects:
      - person
      - dog
      - cat
    
    frigate_birdseye_enabled: true
    frigate_birdseye_mode: "continuous"
  roles:
    - docker
    - frigate
```

### Configuration with Multiple Cameras

```yaml
---
- name: Install Frigate with multiple cameras
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    
    frigate_cameras:
      DoorBell:
        enabled: true
        main_stream: "rtsp://10.30.150.11:554/cam/realmonitor?channel=1&subtype=0"
        sub_stream: "rtsp://10.30.150.11:554/cam/realmonitor?channel=1&subtype=1"
        record: true
        detect: true
      Entrance:
        enabled: true
        main_stream: "rtsp://10.30.150.12:554/cam/realmonitor?channel=1&subtype=0"
        sub_stream: "rtsp://10.30.150.12:554/cam/realmonitor?channel=1&subtype=1"
        record: true
        detect: true
  roles:
    - docker
    - frigate
```

### Usage Without Reboot

```yaml
---
- name: Install Frigate without reboot
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    frigate_reboot_enabled: false
  roles:
    - docker
    - frigate
```

## What This Role Does

1. **Reboots LXC Container (Optional)**
   - Performs system reboot with wait timeout (if `frigate_reboot_enabled: true`)

2. **Creates Working Directories**
   - Creates clips directory: `{{ frigate_clips_dir }}`
   - Creates configuration directory: `{{ frigate_config_dir }}`
   - Sets directory permissions to `0755`

3. **Generates Docker Compose File**
   - Creates Docker Compose file from template `Docker_Compose_Frigate.j2`
   - Configures Frigate container with necessary volumes, ports, and environment variables
   - Configures USB device passthrough for Coral TPU
   - Configures GPU device passthrough for hardware acceleration
   - Configures tmpfs for caching

4. **Generates Frigate Configuration File**
   - Creates `config.yml` file from template `Frigate_Config.j2`
   - Configures detectors (Coral TPU or CPU)
   - Configures go2rtc for video streaming
   - Configures cameras with main and sub streams
   - Configures recording, snapshot, and object detection parameters
   - Configures UI parameters

5. **Runs Frigate as Service**
   - Runs Docker Compose with created configuration file
   - Container starts in detached mode (`-d`)
   - Container configured for automatic restart (`restart: unless-stopped`)

## Configuration Structure

### Docker Compose

The role creates a Docker Compose file with the following characteristics:
- **Image**: `ghcr.io/blakeblackshear/frigate:{{ frigate_version }}`
- **Container**: `frigate_nvr`
- **Mode**: `privileged: true` (required for USB/GPU device access)
- **Volumes**:
  - `/etc/localtime` → time synchronization
  - `{{ frigate_config_dir }}` → configuration
  - `{{ frigate_media_dir }}` → media files
  - tmpfs for cache
- **Ports**: all necessary ports for go2rtc, Frigate UI, RTSP, RTMP, WebRTC

### Frigate Configuration

The configuration file includes the following sections:
- **MQTT**: MQTT broker integration (disabled by default)
- **Detectors**: object detector configuration (Coral TPU or CPU)
- **Birdseye**: overview of all cameras
- **UI**: user interface settings
- **Review**: alerts and detections settings
- **go2rtc**: video streaming configuration
- **FFmpeg**: video processing settings
- **Objects**: object tracking settings
- **Snapshots**: snapshot creation settings
- **Record**: video recording settings
- **Cameras**: camera configuration

## Supported Distributions

- Debian (all versions)
- Ubuntu (all versions)
- Pop!_OS
- Linux Mint
- Proxmox LXC containers (Debian/Ubuntu)

## Coral EDGE TPU Integration

The role supports using Google Coral EDGE TPU for object detection acceleration. To use Coral TPU:

1. Install the `coral-edge-tpu` role before installing Frigate
2. Ensure the Coral TPU USB device is accessible in the container
3. The Frigate configuration will use the `edgetpu` detector

Example detector configuration in template:
```yaml
detectors:
  coral:
    type: edgetpu
    device: usb  # or pci for PCIe version
```

## Camera Configuration

Cameras are configured through the `frigate_cameras` variable or directly in the configuration template. Each camera can have:

- **Main stream**: used for high-quality recording
- **Sub stream**: used for object detection (lower resolution for performance)
- **Roles**: `record` (recording), `detect` (detection)

Example camera configuration in template:
```yaml
cameras:
  DoorBell:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@host:8554/DoorBell_main
          roles:
            - record
        - path: rtsp://user:pass@host:8554/DoorBell_sub
          roles:
            - detect
    live:
      stream_name: DoorBell_main
```

## Shared Memory Size Calculation

The shared memory size (`shm_size`) should be calculated based on the number of cameras and their resolution. Formula:

```
shm_size = (number of cameras) × (width) × (height) × 1.5 × 3 / 1024 / 1024
```

For example, for 4 cameras with 1920x1080 resolution:
```
shm_size = 4 × 1920 × 1080 × 1.5 × 3 / 1024 / 1024 ≈ 37 MB
```

It is recommended to use a value with margin (e.g., 512MB for a small number of cameras).

## Security

### Security Recommendations

1. **Use strong passwords** for `frigate_go2rtc_rtsp_pswd` and `frigate_camera_pswd` variables
2. **Store passwords in Ansible Vault**:
   ```yaml
   ansible-vault encrypt_string 'your_password' --name 'frigate_camera_pswd'
   ```
3. **Restrict port access**:
   - Port `5000` (internal) should be accessible only in Docker network
   - Use reverse proxy for port `8971` (authenticated access)
   - Configure firewall to restrict access to RTSP ports
4. **Use HTTPS** through reverse proxy for web interface
5. **Regularly update** Frigate image to latest version

### Using Ansible Vault

```yaml
---
- name: Install Frigate with protected passwords
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      6638643965393438656438656438656438656438656438656438656438656438...
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      6638643965393438656438656438656438656438656438656438656438656438...
  roles:
    - docker
    - frigate
```

## Notes

- The role automatically creates necessary directories with correct permissions
- The role performs LXC container reboot by default (can be disabled via `frigate_reboot_enabled: false`)
- Configuration files are generated from Jinja2 templates, allowing use of Ansible variables
- The role uses Docker Compose for container management
- Container runs in privileged mode for USB/GPU device access
- For optimal performance, it is recommended to use Coral EDGE TPU
- tmpfs cache size can be configured depending on available memory
- The role supports Ansible check mode

## Troubleshooting

### Container Startup Issues

If the container does not start:

1. **Check container logs**:
   ```bash
   docker logs frigate_nvr
   ```

2. **Check configuration**:
   ```bash
   docker compose -f /opt/docker-compose.yaml config
   ```

3. **Check port availability**:
   ```bash
   netstat -tulpn | grep -E '8971|5000|8554|8555'
   ```

4. **Check directory permissions**:
   ```bash
   ls -la /opt/frigate/
   ```

### Object Detection Issues

If objects are not detected:

1. **Check Coral TPU availability** (if used):
   ```bash
   lsusb | grep -i coral
   ```

2. **Check Frigate logs**:
   ```bash
   docker logs frigate_nvr | grep -i error
   ```

3. **Check detector configuration** in `config.yml`

4. **Ensure camera streams are accessible**:
   ```bash
   ffprobe rtsp://user:pass@host:8554/stream_name
   ```

### Video Recording Issues

If video is not recording:

1. **Check available disk space**:
   ```bash
   df -h /opt/frigate/
   ```

2. **Check media directory permissions**:
   ```bash
   ls -la /opt/frigate/media/
   ```

3. **Check recording settings** in `record` section of configuration

4. **Check FFmpeg logs**:
   ```bash
   docker logs frigate_nvr | grep -i ffmpeg
   ```

### Web Interface Access Issues

If web interface is not accessible:

1. **Check that container is running**:
   ```bash
   docker ps | grep frigate
   ```

2. **Check port availability**:
   ```bash
   curl http://localhost:8971
   ```

3. **Check firewall**:
   ```bash
   iptables -L -n | grep 8971
   ```

4. **Check container logs** for errors

### Reboot Issues

If reboot causes problems:

1. **Disable reboot** via `frigate_reboot_enabled: false`
2. **Perform manual reboot** before running the role
3. **Increase timeout** via `frigate_reboot_timeout`

### Performance Issues

To improve performance:

1. **Use Coral EDGE TPU** instead of CPU detector
2. **Increase shared memory size** (`frigate_shm_size`)
3. **Use separate streams** for recording and detection
4. **Configure hardware acceleration** via GPU devices
5. **Increase tmpfs size** for caching

## Updating Frigate

To update Frigate to a new version:

1. **Change version variable**:
   ```yaml
   frigate_version: "0.16.0"  # or "stable"
   ```

2. **Re-run the role**:
   ```bash
   ansible-playbook playbook.yml -t frigate
   ```

3. **Or update manually via Docker Compose**:
   ```bash
   docker compose -f /opt/docker-compose.yaml pull
   docker compose -f /opt/docker-compose.yaml up -d
   ```

## Monitoring and Maintenance

### Status Check

```bash
# Container status
docker ps | grep frigate

# Container logs
docker logs -f frigate_nvr

# Resource usage
docker stats frigate_nvr
```

### Cleaning Old Recordings

Frigate automatically deletes recordings according to `retain` settings. For manual cleanup:

```bash
# Clean recordings older than 7 days
find /opt/frigate/media/recordings -type f -mtime +7 -delete

# Clean clips older than 30 days
find /opt/frigate/media/clips -type f -mtime +30 -delete
```

### Backup

It is recommended to regularly create backups:

```bash
# Backup configuration
tar -czf frigate-config-backup-$(date +%Y%m%d).tar.gz /opt/frigate/config/
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

## Support

For questions and issues, contact the author or create an issue in the repository.

## Links

- [Official Frigate Documentation](https://docs.frigate.video/)
- [Frigate GitHub Repository](https://github.com/blakeblackshear/frigate)
- [go2rtc Documentation](https://github.com/AlexxIT/go2rtc)
- [Coral EDGE TPU Documentation](https://coral.ai/docs/)

