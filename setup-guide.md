# Setup Guide - Clockwork uConsole on Debian Trixie

Target: Raspberry Pi 5 / CM5 uConsole running Debian Trixie 13 (aarch64). User account `krim` with sudo. Sway is started manually from TTY (no display manager).

## 1. APT packages

```bash
sudo apt update
sudo apt install -y \
  swaybg swayidle waybar foot fuzzel mako-notifier rofi \
  grim slurp clipman feh udiskie blueman \
  brightnessctl autotiling network-manager-gnome \
  fonts-terminus fonts-inconsolata fonts-dejavu fonts-noto fonts-noto-cjk \
  fonts-noto-color-emoji fonts-noto-extra fonts-font-awesome \
  bibata-cursor-theme libnotify-bin \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  zsh git curl gawk vim zoxide \
  pipewire pipewire-pulse wireplumber \
  imagemagick nodejs npm \
  exfat-fuse exfatprogs \
  python3-meshtastic \
  build-essential meson pkg-config cmake scdoc hwdata \
  wayland-protocols libwayland-dev libpcre2-dev libjson-c-dev \
  libpango1.0-dev libcairo2-dev libgdk-pixbuf-2.0-dev \
  libdrm-dev libgbm-dev libinput-dev libseat-dev libxkbcommon-dev \
  libxcb-dri3-dev libxcb-present-dev libxcb-res0-dev \
  libxcb-render-util0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb-composite0-dev libxcb-render0-dev libxcb-shm0-dev \
  libxcb-xinput-dev libxcb-xfixes0-dev libxcb-image0-dev \
  libliftoff-dev libdisplay-info-dev liblcms2-dev libpixman-1-dev \
  libgles2-mesa-dev libpam0g-dev \
  xwayland xserver-xorg-dev libxfixes-dev libxext-dev libxcursor-dev \
  libxi-dev libxkbfile-dev xtrans-dev libxshmfence-dev \
  retroarch \
  libretro-snes9x libretro-mgba libretro-genesisplusgx libretro-nestopia \
  libretro-gambatte libretro-desmume libretro-bsnes-mercury-balanced \
  libretro-beetle-wswan
```

## 2. swayfx from source (with wlroots 0.19 + scenefx 0.4 as Meson subprojects)

Trixie ships wlroots 0.18; swayfx 0.5.3 needs 0.19. Build it via Meson subprojects:

```bash
mkdir -p ~/build && cd ~/build
git clone --depth 1 -b 0.5.3 https://github.com/WillPower3309/swayfx.git
cd swayfx
mkdir -p subprojects && cd subprojects
git clone --depth 1 -b 0.4.1 https://github.com/wlrfx/scenefx.git
git clone --depth 1 -b 0.19.0 https://gitlab.freedesktop.org/wlroots/wlroots.git
cd ~/build/swayfx
meson setup build/
ninja -C build/
sudo ninja -C build/ install
sudo ldconfig
```

Verifications:

```bash
sway --version                                          # swayfx version 0.5.3 ... (based on sway 1.11.0)
pkg-config --variable=have_drm_backend wlroots-0.19     # true
pkg-config --variable=have_xwayland    wlroots-0.19     # true
```

If `have_drm_backend` is `false`, wipe the partial install and rebuild with `hwdata` present:

```bash
sudo rm -rf /usr/local/lib/aarch64-linux-gnu/libwlroots-0.19.so* \
            /usr/local/lib/aarch64-linux-gnu/libscenefx-0.4.so* \
            /usr/local/lib/aarch64-linux-gnu/pkgconfig/wlroots-0.19.pc \
            /usr/local/lib/aarch64-linux-gnu/pkgconfig/scenefx-0.4.pc \
            /usr/local/include/wlroots-0.19 /usr/local/include/scenefx-0.4
sudo ldconfig
rm -rf ~/build/swayfx/build
meson setup ~/build/swayfx/build/
ninja -C ~/build/swayfx/build/
sudo ninja -C ~/build/swayfx/build/ install
sudo ldconfig
```

## 3. swaylock-effects from source

```bash
cd ~/build
git clone --depth 1 https://github.com/mortie/swaylock-effects.git
cd swaylock-effects
meson build/
ninja -C build/
sudo ninja -C build/ install
```

## 4. oh-my-zsh + powerlevel10k

```bash
sudo git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
     /usr/share/oh-my-zsh/custom/themes/powerlevel10k
sudo chsh -s /usr/bin/zsh "$USER"
```

## 5. CLI agent tools (npm global)

```bash
sudo npm i -g @anthropic-ai/claude-code @openai/codex opencode-ai
```

## 6. ES-DE (EmulationStation Desktop Edition)

```bash
mkdir -p ~/Applications && cd ~/Applications
curl -L -o ES-DE_aarch64.AppImage \
  "https://gitlab.com/es-de/emulationstation-de/-/package_files/288156935/download"
chmod +x ES-DE_aarch64.AppImage
sudo ln -sf "$PWD/ES-DE_aarch64.AppImage" /usr/local/bin/es-de
```

## 7. Deploy configs

```bash
mkdir -p ~/.config/{sway,waybar,foot,fuzzel,mako}
cp -r config/sway/*    ~/.config/sway/
cp -r config/waybar/*  ~/.config/waybar/
cp -r config/foot/*    ~/.config/foot/
cp -r config/fuzzel/*  ~/.config/fuzzel/
cp -r config/mako/*    ~/.config/mako/
cp vimrc      ~/.vimrc
cp zshrc      ~/.zshrc
cp zprofile   ~/.zprofile

sudo install -m 0755 -o root -g root audio-hotswitch /usr/local/bin/audio-hotswitch
```

## 8. First start

Boot the device. The TTY shows a normal getty login. Enter your password. `~/.zprofile` checks that you are on TTY1 outside of an existing Wayland session, then `exec sway` takes over.

On first zsh start you will be prompted for `p10k configure` to set up the powerlevel10k prompt.

## 9. exFAT mount helper

```bash
sudo ln -sf mount.exfat-fuse /usr/sbin/mount.exfat
sudo ln -sf mount.exfat-fuse /sbin/mount.exfat
```

## Notes

- DSI panel on `DSI-2`, native 720x1280, rotated to landscape via `transform 90`.
- HDMI auto-mirror not active. swayfx 0.5.3 / sway 1.11.0 has no `output mirror` subcommand.
- `for_window` rules use `[app_id=...]` only; the `[class=...]` selector is unavailable.
- Audio default-sink follows HDMI hotplug via `/usr/local/bin/audio-hotswitch`.
- `~/.zprofile` sources `/etc/profile.d/*.sh` before `exec sway`, so XDG_DATA_DIRS injections (Flatpak exports under `/var/lib/flatpak/exports/share`) reach the Wayland session and Flatpak apps appear in fuzzel.
