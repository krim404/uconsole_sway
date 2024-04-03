#!/bin/sh
swayidle \
    timeout 1 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' &
swaylock --indicator --clock --effect-blur 7x5 -S
kill %%
