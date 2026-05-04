# Setup Guide - Clockwork uConsole on Debian Trixie

Target: Raspberry Pi 5 / CM5 uConsole running Debian Trixie 13 (aarch64). User account `krim` with sudo. Sway is started manually from TTY (no display manager).

## 1. APT packages

```bash
sudo apt update
sudo apt install -y \
  swaybg swayidle swaylock waybar foot fuzzel mako-notifier rofi \
  grim slurp clipman feh udiskie blueman \
  brightnessctl autotiling network-manager-gnome \
  fonts-terminus fonts-inconsolata fonts-dejavu fonts-noto fonts-noto-cjk \
  fonts-noto-color-emoji fonts-noto-extra fonts-font-awesome \
  bibata-cursor-theme libnotify-bin \
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  zsh git curl gawk vim zoxide \
  geany geany-plugins \
  pipewire pipewire-pulse wireplumber \
  imagemagick nodejs npm \
  exfatprogs \
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

## 3. Screen lock

Mainline `swaylock` is sufficient. swaylock-effects (the source-built fork with blur) does **not** work with swayfx / wlroots 0.19 - it relies on the deprecated `wlr_input_inhibitor` protocol that has been removed. Use the package from §1, which speaks the modern `ext-session-lock-v1`.

```bash
# already in §1 apt list, just confirm:
which swaylock         # /usr/bin/swaylock
swaylock --version     # 1.8.x
ls /etc/pam.d/swaylock # ships with the package, do not overwrite
```

The blur effect is faked by feeding swaylock a pre-blurred copy of the wallpaper. A pre-blurred file is shipped in `config/sway/wallpaper-blurred.jpg` and is deployed alongside the rest of the sway config in §7. To regenerate it for a different wallpaper:

```bash
convert ~/.config/sway/wallpaper.jpg -blur 0x8 ~/.config/sway/wallpaper-blurred.jpg
```

The shipped `lock-screen` wrapper (§7) calls `swaylock` with that image, drops the backlight, and listens on the keyboard event device (requires the user to be in the `input` group) to bring the backlight back when the user starts typing and dim it again after 5s of inactivity.

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
mkdir -p ~/.config/{sway,waybar,foot,fuzzel,mako,systemd/user}
cp -r config/sway/*           ~/.config/sway/
cp -r config/waybar/*         ~/.config/waybar/
cp -r config/foot/*           ~/.config/foot/
cp -r config/fuzzel/*         ~/.config/fuzzel/
cp -r config/mako/*           ~/.config/mako/
cp config/systemd/user/*      ~/.config/systemd/user/
cp vimrc      ~/.vimrc
cp zshrc      ~/.zshrc
cp zprofile   ~/.zprofile

sudo install -m 0755 -o root -g root audio-hotswitch /usr/local/bin/audio-hotswitch
sudo install -m 0755 -o root -g root lock-screen      /usr/local/bin/lock-screen

mkdir -p ~/.local/bin
install -m 0755 meshtastic-notifyd ~/.local/bin/meshtastic-notifyd
```

## 7a. Meshtastic notification daemon

Pushes a persistent mako notification (urgency=critical) plus a freedesktop sound
on incoming text messages, logs everything to `~/.local/share/meshtastic/messages.db`.
Connects to `meshtasticd` on `localhost:4403`. Steps aside automatically when another
client (e.g. `gtk-meshtastic-client`) connects to the daemon — `meshtasticd` only allows
one PhoneAPI client at a time.

```bash
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now meshtastic-notifyd.service
systemctl --user status meshtastic-notifyd.service
```

## 7b. Geany as default editor for code and text mimetypes

```bash
DESKTOP=geany.desktop
MIMES=(
  text/plain
  text/x-c text/x-c++ text/x-chdr text/x-csrc text/x-c++hdr text/x-c++src
  text/x-csharp text/x-java text/x-javascript application/javascript
  application/x-javascript text/javascript
  application/json application/x-json text/x-json
  application/xml text/xml text/html application/xhtml+xml
  text/css text/x-scss text/x-sass text/x-less
  text/x-python application/x-python text/x-python3
  text/x-go text/rust text/x-rust text/x-ruby text/x-perl application/x-perl
  text/x-php application/x-php application/x-httpd-php
  application/x-httpd-php3 application/x-httpd-php4 application/x-httpd-php5
  application/sql text/x-sql
  text/x-shellscript application/x-shellscript application/x-sh
  text/x-pascal text/x-dsrc text/x-makefile text/x-cmake
  text/markdown text/x-markdown
  application/yaml application/x-yaml text/yaml text/x-yaml
  application/toml text/x-toml application/x-toml
  text/x-ini text/x-properties text/x-diff text/x-patch text/x-log
  text/x-vala text/x-haskell text/x-erlang text/x-lua
  text/x-tex text/x-asm
  text/csv text/tab-separated-values
  application/x-desktop text/x-dockerfile
  text/x-typescript application/typescript text/vnd.trolltech.linguist
)
for m in "${MIMES[@]}"; do xdg-mime default "$DESKTOP" "$m"; done
```

## 8. First start

Boot the device. The TTY shows a normal getty login. Enter your password. `~/.zprofile` checks that you are on TTY1 outside of an existing Wayland session, then `exec sway` takes over.

On first zsh start you will be prompted for `p10k configure` to set up the powerlevel10k prompt.

## 9. Encrypted `/home` with fscrypt

Per-directory transparent encryption of the user's home, key wrapped with their login passphrase. No second prompt at login, no separate partition, no LUKS in initramfs. The DSI panel on Pi5/CM5 stays black during the initramfs phase, so a cryptsetup-style prompt would not be readable there - this approach sidesteps that entirely.

Set the target user once for all snippets in this section:

```bash
ACCOUNT=krim   # change to your login account
HOME_DIR=/home/$ACCOUNT
```

### 9.1 Prerequisites

Root filesystem must be ext4 with the `encrypt` feature. Trixie's `mkfs.ext4` sets it; verify and turn it on online if missing:

```bash
ROOT_DEV=$(findmnt -no SOURCE /)
sudo tune2fs -l "$ROOT_DEV" | grep -q encrypt || sudo tune2fs -O encrypt "$ROOT_DEV"
```

### 9.2 Install

```bash
sudo apt install -y fscrypt libpam-fscrypt
sudo fscrypt setup --quiet         # global config
sudo fscrypt setup --quiet /       # filesystem-level metadata
```

`libpam-fscrypt` auto-wires into PAM via `pam-auth-update`. Verify:

```bash
grep -h fscrypt /etc/pam.d/common-{auth,password,session}
# auth     optional    pam_fscrypt.so
# password optional    pam_fscrypt.so
# session  optional    pam_fscrypt.so
```

### 9.3 Encrypt the home directory before the user's first regular login

Only an empty directory can be encrypted. Two paths depending on whether `$HOME_DIR` already has real data.

**A) Fresh setup (no real data in `$HOME_DIR` yet):**

```bash
sudo passwd "$ACCOUNT"                       # set/confirm login passphrase first
sudo rm -rf "$HOME_DIR"
sudo install -d -m 700 -o "$ACCOUNT" -g "$ACCOUNT" "$HOME_DIR"

sudo fscrypt encrypt "$HOME_DIR" --user="$ACCOUNT" --source=pam_passphrase --no-recovery
# Prompts once for the account's login passphrase.

sudo cp -a /etc/skel/. "$HOME_DIR/"
sudo chown -R "$ACCOUNT":"$ACCOUNT" "$HOME_DIR"
```

**B) Existing system with data in `$HOME_DIR` (rename, encrypt new, rsync):**

```bash
sudo mv "$HOME_DIR" "${HOME_DIR}.old"
sudo install -d -m 700 -o "$ACCOUNT" -g "$ACCOUNT" "$HOME_DIR"
sudo fscrypt encrypt "$HOME_DIR" --user="$ACCOUNT" --source=pam_passphrase --no-recovery
sudo rsync -aHAX "${HOME_DIR}.old/" "$HOME_DIR/"
# Verify with a fresh login (logout, log back in), then:
sudo rm -rf "${HOME_DIR}.old"
```

### 9.4 Verify

```bash
sudo fscrypt status "$HOME_DIR"
# "Unlocked: Yes" right after a fresh login of $ACCOUNT
# "Unlocked: No"  once that account's last session ends
```

`pam_fscrypt` derives the key from the login passphrase. Reboot, log in normally, the home becomes readable; on logout / reboot it becomes opaque again (root sees only ciphertext filename stubs, file contents are inaccessible).

## 10. Persistent SD-card auto-mount (no sway required)

The second SD card slot (exposed via the carrier's USB bridge as `/dev/sda`) mounts at boot via `/etc/fstab`, independent of any desktop-session auto-mounter. `nofail` keeps boot snappy if the card is missing.

Trixie's kernel has native exFAT support (`exfat.ko`); only `exfatprogs` is needed for `mkfs.exfat` / `fsck.exfat`. The `exfat-fuse` package is optional and only relevant for older kernels - if it is installed, it ships `mount.exfat → mount.exfat-fuse` symlinks that force every `mount -t exfat` through FUSE. Remove those symlinks (or purge `exfat-fuse`) to use the kernel driver:

```bash
sudo apt install -y exfatprogs
sudo apt purge -y exfat-fuse 2>/dev/null || true
sudo rm -f /sbin/mount.exfat /usr/sbin/mount.exfat   # leftover symlinks if any
```

Identify the data partition (commonly `/dev/sda2` for an exFAT card with a leading EFI/MBR partition) and add a fstab entry. `uid/gid` give the owning account write access:

```bash
SD_PART=/dev/sda2
SD_UUID=$(sudo blkid -s UUID -o value "$SD_PART")
ACCOUNT_UID=$(id -u "$ACCOUNT")
ACCOUNT_GID=$(id -g "$ACCOUNT")

sudo mkdir -p /mnt/sdcard
echo "UUID=$SD_UUID  /mnt/sdcard  exfat  defaults,nofail,uid=$ACCOUNT_UID,gid=$ACCOUNT_GID,umask=0022,x-systemd.device-timeout=5  0  0" \
  | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
mount | grep /mnt/sdcard      # should show "type exfat", not "fuseblk"
```

The card mounts at `/mnt/sdcard` early during boot, before any user logs in. udisks2 inside a sway session sees it as already mounted and leaves it alone.

## Notes

- DSI panel on `DSI-2`, native 720x1280, rotated to landscape via `transform 90`.
- HDMI auto-mirror not active. swayfx 0.5.3 / sway 1.11.0 has no `output mirror` subcommand.
- `for_window` rules use `[app_id=...]` only; the `[class=...]` selector is unavailable.
- Audio default-sink follows HDMI hotplug via `/usr/local/bin/audio-hotswitch`.
- `~/.zprofile` sources `/etc/profile.d/*.sh` before `exec sway`, so XDG_DATA_DIRS injections (Flatpak exports under `/var/lib/flatpak/exports/share`) reach the Wayland session and Flatpak apps appear in fuzzel.
