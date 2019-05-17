#!/usr/bin/env bash

set -e
set -u
set -o pipefail

##/=====================================\
##|      DETECT PLATFORM      |
##\=====================================/
case $OSTYPE in
  darwin*) OS="darwin";;
  linux-gnu*) OS="linux";;
  *) echo "OS $OS not supported by the installation script"; exit 1;;
esac

case $(uname -m) in
  amd64) ARCH="amd64";;
  x86_64) ARCH="amd64";;
  *) echo "Architecture $ARCH not supported by the installation script"; exit 1;;
esac

BIN="$HOME/bin"

##/=====================================\
##|     CLEAN OLD INSTALLATION |
##\=====================================/

if [ "$(command -v nigiri)" != "" ]; then
  echo "Nigiri is already installed and will be deleted."
  echo "Stopping Nigiri..."
  if [ -z "$(nigiri stop --delete &>/dev/null)" ]; then
    :
  fi
  echo "Removing Nigiri..."
  rm -f $BIN/nigiri
  rm -rf ~/.nigiri
fi

mkdir -p $BIN

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

curl -sL $RELEASE_URL > nigiri

case $SHELL in
  *zsh) PROFILE="$HOME/.zshrc";;
  *ksh) PROFILE="$HOME/.kshrc";;
  *bash)
    if [ -f "$HOME/.bash_profile" ]; then
      PROFILE="$HOME/.bash_profile"
    elif [ -f "$HOME/.bash_login" ]; then
      PROFILE="$HOME/.bash_login"
    elif [ -f "$HOME/.profile" ]; then
      PROFILE="$HOME/.profile"
    fi
    ;;
  *csh)
    if [ -f "$HOME/.tcshrc" ]; then
      PROFILE="$HOME/.tcshrc"
    elif [ -f "$HOME/.cshrc" ]; then
      PROFILE="$HOME/.cshrc"
    fi
    ;;
esac

echo "Moving binary to $BIN..."
mv nigiri $BIN

echo "Setting binary permissions..."
chmod +x $BIN/nigiri

if [ "$PATH" != *"$BIN"* ]; then
  echo "Exporting path..."
  echo "export PATH=\$PATH:\$HOME/bin" >> $PROFILE
fi

echo "Creating data directory ~/.nigiri..."
URL="https://raw.githubusercontent.com/vulpemventures/nigiri/$TAG/resources"
NIGIRI_FOLDER=~/.nigiri/resources
REGTEST_VOLUME=volumes/regtest
LIQUID_VOLUME=volumes/liquidregtest
REGTEST_FOLDER=$NIGIRI_FOLDER/$REGTEST_VOLUME
REGTEST_COMPOSE_FILE=docker-compose-regtest.yml
LIQUID_FOLDER=$NIGIRI_FOLDER/$LIQUID_VOLUME
LIQUID_COMPOSE_FILE=docker-compose-regtest-liquid.yml

mkdir -p $REGTEST_FOLDER/config
mkdir -p $LIQUID_FOLDER/config
mkdir -p $LIQUID_FOLDER/liquid-config

curl -o $NIGIRI_FOLDER/$REGTEST_COMPOSE_FILE -sL "$URL/$REGTEST_COMPOSE_FILE"
curl -o $NIGIRI_FOLDER/$LIQUID_COMPOSE_FILE -sL "$URL/$LIQUID_COMPOSE_FILE"
curl -o $REGTEST_FOLDER/config/bitcoin.conf -sL "$URL/$REGTEST_VOLUME/config/bitcoin.conf"
curl -o $LIQUID_FOLDER/config/bitcoin.conf -sL "$URL/$LIQUID_VOLUME/config/bitcoin.conf"
curl -o $LIQUID_FOLDER/liquid-config/liquid.conf -sL "$URL/$LIQUID_VOLUME/liquid-config/liquid.conf"

echo "Checking for Docker and Docker compose..."
if [ "$(command -v docker)" == "" ]; then
  echo "Warning: Nigiri uses Docker and it seems not to be installed, check the official documentation for downloading it.";
  if [ "$OS" = "darwin" ]; then
    echo "https://docs.docker.com/v17.12/docker-for-mac/install/#download-docker-for-mac"
  else
    echo "https://docs.docker.com/v17.12/install/linux/docker-ce/ubuntu/"
  fi 
fi

echo ""
echo "🍣 Nigiri Bitcoin installed. Data directory: ~/.nigiri"
