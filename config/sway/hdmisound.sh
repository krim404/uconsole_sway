#!/bin/bash
sleep 4
USER="krim"
echo $(whoami) > /tmp/runda
# Get user's Wayland socket
XDG_RUNTIME_DIR=/run/user/$(id -u $USER)
WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR/wayland-*)

# Export required env vars  
export XDG_RUNTIME_DIR
export WAYLAND_DISPLAY

pulseaudio -k
pactl load-module module-detect
pactl load-module module-alsa-sink
