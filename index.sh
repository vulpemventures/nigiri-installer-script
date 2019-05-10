#!/usr/bin/env bash

set -e
set -u
set -o pipefail


##/=====================================\
##|      DETECT PLATFORM      |
##\=====================================/
case $OSTYPE in
  darwin*) OS="darwin"; BIN="/usr/local/bin";;
  linux-gnu*) OS="linux"; BIN="/usr/bin";;
  *) echo "OS $OS not supported by the installation script"; exit 1;;
esac

case $(uname -m) in
  amd64) ARCH="amd64";;
  x86_64) ARCH="amd64";;
  *) echo "Architecture $ARCH not supported by the installation script"; exit 1;;
esac

##/=====================================\
##|     FETCH LATEST RELEASE      |
##\=====================================/
LATEST_RELEASE=$(curl -sL -H 'Accept: application/json' https://github.com/vulpemventures/nigiri/releases/latest)
TAG=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

echo "Installing Nigiri $TAG on $OS $ARCH..."
URL="https://github.com/vulpemventures/nigiri/releases/download/$TAG/nigiri-$OS-$ARCH"
curl -sL $URL > nigiri

echo "Moving binary to $BIN..."
mv nigiri $BIN
chmod +x $BIN/nigiri 

echo "Scratching ~/.nigiri..."
URL="https://raw.githubusercontent.com/vulpemventures/nigiri/master/resources"
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
command -v docker >/dev/null 2>&1 || {
  echo "Warning: Nigiri uses Docker and it seems not to be installed, check the official documentation for downloading it.";
  if [ $OS = "darwin" ]; then
    echo "https://docs.docker.com/v17.12/docker-for-mac/install/#download-docker-for-mac"
  else
    echo "https://docs.docker.com/v17.12/install/linux/docker-ce/ubuntu/"
  fi 
}

echo ""
echo "🍣 Nigiri Bitcoin installed. Data directory: ~/.nigiri"