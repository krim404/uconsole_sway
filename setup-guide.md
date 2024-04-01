# Setup Guide

This guide assumes you have a working Alpine Linux setup with the Sway window manager already installed.

## Additional Packages

Install the following packages for fonts, utilities, and Waybar dependencies:

```
sudo apk add font-terminus font-inconsolata font-dejavu font-noto font-noto-cjk font-awesome font-noto-extra \
        autotiling zoxide py3-pip blueman brightnessctl waybar network-manager-applet curl zsh gawk \
        grim slurp feh clipman vim udiskie 
```

## Oh My ZSH 
```
sudo apk add oh-my-zsh
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`
```

## Configs
copy the content of `config` to `~/.config` and the `vimrc` and `zshrc` to `~/.vimrc` / `~/.zshrc`

## Compile of RetroArch

```
apk add linux-headers mesa-dev qt5-qtbase-dev wayland-dev wayland-protocols zlib-dev alsa-lib-dev pulseaudio-dev sdl2-dev flac-dev mbedtls-dev libusb-dev openssl-dev>3 ffmpeg-dev libxkbcommon-dev eudev-dev vulkan-loader-dev
git clone https://github.com/libretro/RetroArch -b v1.18.0 
CFLAGS='-march=native' ./configure  --disable-videocore --disable-opengl1 --enable-opengles --enable-opengles3 --enable-opengles3_1 --enable-pulse --enable-udev --enable-ssl --enable-vulkan --enable-kms --enable-egl
```
