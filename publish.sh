#!/bin/bash

aws s3 cp ./index.sh s3://getnigiri.vulpem.com/index.sh \
  --content-type 'text/plain' \
  --cache-control 'max-age=60' \
  --acl public-read