#!/bin/bash
# Build and install Walker (GTK4 launcher) + elephant provider daemon and a
# curated set of providers as Go plugins. Run as the regular user; sudo is
# only invoked for apt-get and `install` into /usr/local.
#
# Idempotent: re-running re-pulls the repos and rebuilds.

set -euo pipefail

BUILD_DIR="${BUILD_DIR:-$HOME/build}"
PROVIDERS=(
    desktopapplications
    files
    calc
    websearch
    runner
    clipboard
    symbols
    bookmarks
    providerlist
)

echo "==> 1/5 install build deps + runtime helpers"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    rustup \
    libgtk-4-dev libgtk4-layer-shell-dev protobuf-compiler \
    libpoppler-glib-dev libcairo2-dev pkg-config \
    golang-go make \
    qalc fd-find

# qalc is used by the calc provider, fd-find provides /usr/bin/fdfind for
# the files provider. Walker calls fd, so symlink:
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

echo "==> 2/5 ensure rustup stable toolchain (apt rustc 1.85 is too old)"
rustup toolchain install stable
rustup default stable

mkdir -p "$BUILD_DIR"

echo "==> 3/5 clone + build elephant daemon (Go)"
if [ ! -d "$BUILD_DIR/elephant" ]; then
    git clone --depth 1 https://github.com/abenz1267/elephant.git "$BUILD_DIR/elephant"
fi
cd "$BUILD_DIR/elephant"
git pull --ff-only || true
make build
sudo install -Dm 755 cmd/elephant/elephant /usr/local/bin/elephant

echo "==> 4/5 build elephant provider plugins (.so) into /usr/local/lib/elephant"
sudo mkdir -p /usr/local/lib/elephant
for p in "${PROVIDERS[@]}"; do
    DIR="$BUILD_DIR/elephant/internal/providers/$p"
    if [ ! -d "$DIR" ]; then
        echo "  skip $p (source dir missing)"
        continue
    fi
    echo "  building $p"
    (cd "$DIR" && go build -buildvcs=false -buildmode=plugin -trimpath -o "${p}.so")
    sudo install -Dm 755 "$DIR/${p}.so" "/usr/local/lib/elephant/${p}.so"
done

echo "==> 5/5 clone + build walker (Rust + GTK4)"
if [ ! -d "$BUILD_DIR/walker" ]; then
    git clone --depth 1 https://github.com/abenz1267/walker.git "$BUILD_DIR/walker"
fi
cd "$BUILD_DIR/walker"
git pull --ff-only || true
cargo build --release
sudo install -Dm 755 target/release/walker /usr/local/bin/walker

echo
echo "Done."
echo "  elephant -> $(elephant --version 2>&1 | head -1 || true)"
echo "  walker   -> $(walker --version 2>&1 | head -1 || true)"
echo
echo "Plugins installed:"
ls /usr/local/lib/elephant/
