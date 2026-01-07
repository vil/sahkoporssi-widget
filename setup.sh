#! /usr/bin/env bash

# Vili <https://vili.dev>

set -e

PLASMOID_DIR=$(dirname "$0")/package
plasmoidName="dev.vili.sahkoporssi"
filename="${plasmoidName}.tar"
cd "$PLASMOID_DIR"
tar -cvf $filename *
cd -
mkdir -p dist
mv "$PLASMOID_DIR"/$filename dist/$filename
echo "md5: $(md5sum dist/$filename | awk '{ print $1 }')"
echo "sha256: $(sha256sum dist/$filename | awk '{ print $1 }')"
plasmapkg2 -i dist/$filename
echo "Done..! Check your widget menu!"
