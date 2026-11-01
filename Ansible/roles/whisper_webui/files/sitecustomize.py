"""Restore the torch<2.6 torch.load default for the bundled pyannote models.

PyTorch 2.6+ defaults weights_only=True, and the pyannote 3.3.x checkpoints
shipped with speaker-diarization-3.1 pickle objects (torch.torch_version,
OmegaConf nodes) that the new default refuses to unpickle. Callers cannot
override it, so the venv-wide sitecustomize restores the legacy default the
application was written for. The checkpoints arrive over authenticated HTTPS
from the trusted pyannote repositories, which matches the torch<2.6 trust
model; explicit weights_only arguments still take precedence.
"""

import torch as _torch

_load_orig = _torch.load


def _load_allow_pickled(*args, **kwargs):
    kwargs.setdefault("weights_only", False)
    return _load_orig(*args, **kwargs)


_torch.load = _load_allow_pickled
