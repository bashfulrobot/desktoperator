#!/usr/bin/env bash
# Vibe Transcribe launcher
# Suppresses unnecessary audio backend probe errors

set -euo pipefail

# Force PulseAudio/PipeWire backend (skip JACK, OSS, ALSA probes)
export SDL_AUDIODRIVER=pulseaudio

# Suppress GTK theme warnings
export GTK_THEME=Adwaita:dark

# Redirect ALSA/JACK errors to null
exec vibe "$@" 2> >(grep -v -E "ALSA lib|jack server|JackShmReadWritePtr|Cannot connect to server|/dev/dsp|dmix plugin|dsnoop plugin|channel map" >&2)
