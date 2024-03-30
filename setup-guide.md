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

## Configs
copy the content of `config` to `~/.config` and the `vimrc` and `zshrc` to `~/.vimrc` / `~/.zshrc`
