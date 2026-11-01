# whisper_webui

This role deploys [Whisper-WebUI](https://github.com/jhj0517/Whisper-WebUI) —
a speech-to-text web interface on top of faster-whisper running CPU inference.
In the HomeLab it applies to the `stt` LXC (`172.25.40.204`) on pve-main; the
UI is published through Traefik as `stt.dragons-nest.home.arpa`.

## What it does

- Installs system packages: `git`, `ffmpeg`, `rubberband-cli`, Python and the
  build toolchain.
- Creates the system account and the data directory `/opt/whisper-webui-data`
  (models and outputs live outside the versioned tree).
- Downloads the Whisper-WebUI release tarball into
  `/opt/Whisper-WebUI-<version>` and switches the `/opt/whisper-webui` symlink.
- Patches `requirements.txt`: drops the PyTorch wheel index (its wheel host
  `download-r2.pytorch.org` is unreachable from the lab WAN) and pins the git+
  dependencies to reviewed commits (`whisper_webui_pinned_git_deps`) so the pip
  run is idempotent.
- Downloads the `torch`/`torchaudio` CPU wheels through the CloudFront front
  end `download.pytorch.org` and installs them from local files before the
  requirements run.
- The `jhj0517-whisper` fork is installed from a locally patched clone in
  `/opt/whisper-webui-build`: its `exec()`/`locals()` version reader is
  incompatible with Python 3.13 (PEP 667), and `pkg_resources` requires
  `setuptools<81` inside the build environment (`PIP_CONSTRAINT`).
- Appends `av>=11,<16` (PyAV 16+ removed the `metadata_errors` kwarg that
  faster-whisper passes to `av.open`) and `matplotlib` (pyannote imports it
  but upstream does not declare it) to `requirements.txt`.
- Builds the venv and installs the Python dependencies (CPU PyTorch,
  faster-whisper, gradio, pyannote, UVR).
- Patches `modules/diarize/diarize_pipeline.py` to restore `torch.load`'s
  `weights_only=False` default: pyannote 3.3.x checkpoints pickle objects
  torch 2.6+ refuses by default; models come from the trusted pyannote repos
  over authenticated HTTPS, matching the torch<2.6 trust model.
- With `whisper_webui_diarize_merge: true` also patches
  `modules/diarize/diarizer.py` so consecutive same-speaker segments merge
  into paragraph blocks before the `SPEAKER_XX|` prefix; txt/srt outputs
  arrive already merged.
- Renders `configs/default_parameters.yaml` (preselected model, language, VAD,
  diarization token) and the `whisper-webui.service` systemd unit.
- Installs `/usr/local/bin/whisper-merge-speakers`: post-processes a diarized
  txt by merging runs of identical `SPEAKER_XX` labels into paragraphs and
  writes `<name>_merged.txt` next to the input
  (`whisper-merge-speakers file.txt`).
- Preloads the listed faster-whisper models into the shared data directory.
- Manages the service state; restarts go through the handler.

## Requirements

- Target OS: Debian (enforced by assert; the lab deployment is Debian 13).
- `become: true`; `become_user` is used for model preloading (sudo is installed
  by the `base_install_packages` role earlier in the playbook).
- Outbound internet access on the host: GitHub tarball, pip packages, Hugging
  Face model downloads.
- Secrets are passed as variable names resolved in `VARS/secrets.yml` only.

## Managed resources

- Packages: `git`, `ffmpeg`, `rubberband-cli`, `python3`, `python3-dev`,
  `python3-venv`, `python3-packaging`, `build-essential`, `ca-certificates`
- Files: `/opt/Whisper-WebUI-<version>/`, `/opt/whisper-webui` symlink,
  `/opt/whisper-webui-data`, `requirements.txt` inside the tree,
  `configs/default_parameters.yaml`, `/etc/systemd/system/whisper-webui.service`
- Services: `whisper-webui`
- Users/groups: `stt` system account (default)
- Firewall/API objects: none

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `whisper_webui_debug_mode` | bool | no | `false` | Debug output after changes. |
| `whisper_webui_version` | string | no | `"1.0.8"` | Whisper-WebUI release without the leading `v`. |
| `whisper_webui_download_url` | string | no | GitHub tarball | Release archive URL. |
| `whisper_webui_release_dir` | string | no | `/opt/Whisper-WebUI-<version>` | Unpacked release directory. |
| `whisper_webui_pinned_git_deps` | dict | no | see defaults | Commits for the git+ requirements; review on version bump. |
| `whisper_webui_whisper_fork_commit` | string | no | `19724431…` | Pinned commit of the jhj0517-whisper fork. |
| `whisper_webui_build_root` | string | no | `"/opt/whisper-webui-build"` | Directory of the patched fork clone. |
| `whisper_webui_build_constraints` | string | no | `"setuptools<81"` | Contents of the `PIP_CONSTRAINT` build file. |
| `whisper_webui_install_root` | string | no | `"/opt/whisper-webui"` | Symlink to the release directory. |
| `whisper_webui_data_root` | string | no | `"/opt/whisper-webui-data"` | Models and outputs outside the release tree. |
| `whisper_webui_system_user` | string | no | `"stt"` | Service system account. |
| `whisper_webui_packages` | list | no | see defaults | System packages. |
| `whisper_webui_torch_wheels` | list | no | torch/torchaudio 2.8.0+cpu, torchvision 0.23.0+cpu | CPU PyTorch wheels ({package, version}) installed from files via the CloudFront front end. |
| `whisper_webui_torch_wheel_base_url` | string | no | `https://download.pytorch.org/whl/cpu/` | Base URL of the PyTorch wheel index front end. |
| `whisper_webui_server_name` | string | no | `"0.0.0.0"` | Gradio bind address. |
| `whisper_webui_server_port` | int | no | `7860` | Gradio port. |
| `whisper_webui_root_path` | string | no | `""` | Public sub-path behind a proxy. |
| `whisper_webui_allowed_paths` | string/empty | no | `{{ data_root }}/outputs` | Directory added to Gradio `allowed_paths` so result files can be returned. |
| `whisper_webui_diarize_merge` | bool | no | `true` | Merge consecutive same-speaker segments into paragraphs (diarizer.py patch). |
| `whisper_webui_auth_user_var` | string/null | no | `null` | Name of the variable holding the basic-auth user; both or neither. |
| `whisper_webui_auth_password_var` | string/null | no | `null` | Name of the variable holding the basic-auth password. |
| `whisper_webui_default_model` | string | no | `"large-v3-turbo"` | Preselected faster-whisper model. |
| `whisper_webui_default_language` | string | no | `"Russian"` | Preselected transcription language. |
| `whisper_webui_default_file_format` | string | no | `"SRT"` | Preselected output format. |
| `whisper_webui_vad_filter` | bool | no | `true` | Preselected Silero VAD filter. |
| `whisper_webui_diarization_token_var` | string/null | no | `null` | Name of the variable holding the HF token for pyannote. |
| `whisper_webui_preload_models` | list | no | `["large-v3-turbo"]` | Models downloaded during deployment. |
| `whisper_webui_model_repos` | dict | no | `{large-v3-turbo: mobiuslabsgmbh/…}` | HF repo override per model name (preload idempotency check). |
| `whisper_webui_hf_endpoint` | string/empty | no | `""` | `HF_ENDPOINT` for the service and preloader (mirror when HF CDNs are unreachable). |
| `whisper_webui_cpu_threads` | int | no | `4` | `OMP_NUM_THREADS` for inference. |
| `whisper_webui_service_state` | string | no | `"started"` | Stable service state. |
| `whisper_webui_service_enabled` | bool | no | `true` | Enable the service at boot. |

## Usage

```yaml
---
- name: Install Whisper-WebUI
  hosts: stt
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: whisper_webui
      vars:
        whisper_webui_cpu_threads: 8
        whisper_webui_auth_user_var: vault_whisper_webui_admin_user
        whisper_webui_auth_password_var: vault_whisper_webui_admin_password
```

## Check mode and diff mode

The role generally supports `--check --diff`: packages, directories, templates
and the service report predicted changes. Limitations:

- `unarchive` and `command` (venv, model preloading) are skipped in check mode —
  they are external downloads that cannot be predicted.
- Templates containing secrets and the unit file use `no_log`/`diff: false`, so
  no diff is shown for them.

## Dependencies

- None. In the playbook the role follows `base_install_packages` and
  `base_set_locale`.

## Notes

- The basic-auth password is passed as a command-line argument and is visible
  in the host's process list; the unit file is readable by root only. It is a
  fallback barrier — the real access boundary is Traefik + Keycloak.
- Diarization (pyannote) requires an HF token with accepted terms for
  `pyannote/speaker-diarization-3.1` and `pyannote/segmentation-3.0`; without
  `whisper_webui_diarization_token_var` the feature does not work in the UI.
- The PyTorch wheel index in `requirements.txt` is dropped:
  `download-r2.pytorch.org` is unreachable from the lab WAN, so `torch` and
  `torchaudio` are installed from local CPU wheels fetched through the
  CloudFront front end `download.pytorch.org`.
- When bumping `whisper_webui_version`, review and re-pin the commits in
  `whisper_webui_pinned_git_deps` and the `default_parameters.yaml` template
  against upstream.
- The service is published separately through Traefik as
  `stt.dragons-nest.home.arpa`; the route and the pfSense Host Override are
  configured outside this role.
