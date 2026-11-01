"""Restore the torch<2.6 torch.load default for the bundled pyannote models.

PyTorch 2.6+ defaults weights_only=True, and lightning passes the flag
explicitly, so a plain setdefault cannot restore the legacy behaviour. The
pyannote 3.3.x checkpoints shipped with speaker-diarization-3.1 pickle
torch.torch_version and OmegaConf objects that the new default refuses, so
the flag is forced here for the whole venv. The checkpoints arrive over
authenticated HTTPS from the trusted pyannote repositories, matching the
torch<2.6 trust model this application was written for.
"""

import torch as _torch

_load_orig = _torch.load


def _load_allow_pickled(*args, **kwargs):
    kwargs["weights_only"] = False
    return _load_orig(*args, **kwargs)


_torch.load = _load_allow_pickled
