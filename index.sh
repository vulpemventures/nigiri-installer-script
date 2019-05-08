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


LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/vulpemventures/nigiri/releases/latest)
TAG=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
echo $TAG

url="https://github.com/vulpemventures/nigiri/releases/download/$TAG/nigiri-$platform-$arch"
echo $url
curl -L $url > nigiri


osx_bin_folder="/usr/local/bin/"
mv nigiri $osx_bin_folder
chmod +x $osx_bin_folder/nigiri 

echo "🍣 Nigiri Bitcoin installed. Local data directory: ~/.nigiri"



