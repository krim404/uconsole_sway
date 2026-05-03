# Apply /etc/profile.d snippets. Debian's /etc/zsh/zprofile does not source
# /etc/profile, so this needs to happen explicitly for zsh login shells.
if [[ -d /etc/profile.d ]]; then
    emulate sh -c '
        for f in /etc/profile.d/*.sh; do
            [ -r "$f" ] && . "$f"
        done
    '
fi

# Auto-start sway after the first login on TTY1 since boot.
# /tmp is tmpfs on Debian Trixie, so the flag is cleared on reboot.
# After sway exits, the flag remains for the rest of the boot, so a
# subsequent TTY1 login drops to the shell instead of re-launching sway.
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" = "1" && ! -e /tmp/.sway-started-$USER ]]; then
    touch /tmp/.sway-started-$USER
    exec sway
fi
