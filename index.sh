#!/usr/bin/env bash

set -e
set -u
set -o pipefail

function remove_images() {
  image_repos=(
    ghcr.io/vulpemventures/elements
    ghcr.io/vulpemventures/electrs
    ghcr.io/vulpemventures/electrs-liquid
    ghcr.io/vulpemventures/esplora
    ghcr.io/vulpemventures/nigiri-chopsticks
    ghcr.io/getumbrel/docker-bitcoind
    lightninglabs/lnd
    lightninglabs/taproot-assets
    elementsproject/lightningd
    ghcr.io/arkade-os/arkd-wallet
    ghcr.io/arkade-os/arkd
  )
  
  for repo in ${image_repos[*]}; do
    matching_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${repo}:" 2>/dev/null || true)
    
    if [ -n "$matching_images" ]; then
      echo "$matching_images" | while read -r image; do
        docker rmi "$image" 1>/dev/null && echo "successfully deleted $image" || true
      done
    fi
  done
}

##/=====================================\
##|      DETECT PLATFORM      |
##\=====================================/
case $OSTYPE in
darwin*) OS="darwin" ;;
linux-gnu*) OS="linux" ;;
*)
  echo "OS $OSTYPE not supported by the installation script"
  exit 1
  ;;
esac

case $(uname -m) in
amd64) ARCH="amd64" ;;
arm64) ARCH="arm64" ;;
x86_64) ARCH="amd64" ;;
*)
  echo "Architecture $ARCH not supported by the installation script"
  exit 1
  ;;
esac

OLD_BIN="$HOME/bin"
BIN="/usr/local/bin"

##/=====================================\
##|     CLEAN OLD INSTALLATION |
##\=====================================/

if [ "$(command -v nigiri)" != "" ]; then
  echo "Nigiri is already installed and will be deleted."
  # check if Docker is running
  if [ -z "$(docker info 2>&1 >/dev/null)" ]; then
    :
  else
    echo
    echo "Info: when uninstalling an old Nigiri version Docker must be running."
    echo
    echo "Be sure to start the Docker daemon before launching this installation script."
    echo
    #exit 1
  fi

  echo "Stopping Nigiri..."
  if [ -z "$(nigiri stop --delete &>/dev/null)" ]; then
    :
  fi

  echo "Removing Nigiri..."
  sudo rm -f $BIN/nigiri
  sudo rm -f $OLD_BIN/nigiri
  sudo rm -rf ~/.nigiri

  echo "Removing local images..."
  remove_images
fi

##/=====================================\
##|     FETCH LATEST RELEASE      |
##\=====================================/
NIGIRI_URL="https://github.com/vulpemventures/nigiri/releases"
LATEST_RELEASE_URL="$NIGIRI_URL/latest"

echo "Fetching $LATEST_RELEASE_URL..."

TAG=$(curl -sL -H 'Accept: application/json' $LATEST_RELEASE_URL | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

echo "Latest release tag = $TAG"

RELEASE_URL="$NIGIRI_URL/download/$TAG/nigiri-$OS-$ARCH"

echo "Fetching $RELEASE_URL..."

curl -sL $RELEASE_URL >nigiri

echo "Moving binary to $BIN..."
sudo mv nigiri $BIN

echo "Setting binary permissions..."
sudo chmod +x $BIN/nigiri

echo "Checking for Docker and Docker compose..."
if [ "$(command -v docker)" == "" ]; then
  echo "Warning: Nigiri uses Docker and it seems not to be installed, check the official documentation for downloading it."
  if [ "$OS" = "darwin" ]; then
    echo "https://docs.docker.com/v17.12/docker-for-mac/install/#download-docker-for-mac"
  else
    echo "https://docs.docker.com/v17.12/install/linux/docker-ce/ubuntu/"
  fi
fi

echo ""
echo "🍣 Nigiri Bitcoin installed!"
