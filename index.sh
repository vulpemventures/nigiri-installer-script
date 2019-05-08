#!/usr/bin/env bash

set -e
set -u
set -o pipefail

function githubLatestTag {
    echo curl --silent "https://github.com/$1/releases/latest" | sed 's#.*tag/\(.*\)\".*#\1#'
}


##/=====================================\
##|      DETECT PLATFORM      |
##\=====================================/
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX
  platform="darwin"
fi
if [[ $(uname -m) == "x86_64" ]]; then
  arch='amd64'
fi

echo "Installing Nigiri on $platform..."
##/=====================================\
##|     FETCH LATEST RELEASE      |
##\=====================================/
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/vulpemventures/nigiri/releases/latest)
TAG=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
url="https://github.com/vulpemventures/nigiri/releases/download/$TAG/nigiri-$platform-$arch"
curl -sL $url > nigiri

# Move in bin folder
osx_bin_folder="/usr/local/bin/"
mv nigiri $osx_bin_folder
chmod +x $osx_bin_folder/nigiri 

echo ""
echo "🍣 Nigiri Bitcoin installed. Data directory: ~/.nigiri"



