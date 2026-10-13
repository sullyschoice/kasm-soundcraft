#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

REPO="storytold/soundcraft"

# Map the Debian architecture to the naming used in the release assets
case "$(dpkg --print-architecture)" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y curl ca-certificates

# Use SOUNDCRAFT_VERSION if given (e.g. 0.6.1), otherwise resolve the latest release tag.
# The /releases/latest redirect avoids the unauthenticated GitHub API rate limit.
if [ -z "${SOUNDCRAFT_VERSION}" ]; then
  TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" | sed 's#.*/tag/##')
  SOUNDCRAFT_VERSION="${TAG#v}"
fi

DEB="soundcraft-${SOUNDCRAFT_VERSION}-linux-${ARCH}.deb"
BASE_URL="https://github.com/${REPO}/releases/download/v${SOUNDCRAFT_VERSION}"

mkdir -p /tmp/soundcraft
cd /tmp/soundcraft
curl -fsSL -o "${DEB}" "${BASE_URL}/${DEB}"
curl -fsSL -o SHA256SUMS.txt "${BASE_URL}/SHA256SUMS.txt"
grep " ${DEB}\$" SHA256SUMS.txt | sha256sum -c -

# Recommends pulls in mesa-vulkan-drivers / libegl-mesa0 for software rendering without a GPU
apt-get install -y --install-recommends "./${DEB}"

# Desktop shortcut
mkdir -p $HOME/Desktop
cp /usr/share/applications/ai.storyteller.soundcraft.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/ai.storyteller.soundcraft.desktop
chown 1000:1000 $HOME/Desktop/ai.storyteller.soundcraft.desktop

# Cleanup
cd /
rm -rf /tmp/soundcraft
apt-get autoclean
rm -rf /var/lib/apt/lists/* /var/tmp/*
