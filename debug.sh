#! /usr/bin/env bash

# Vili <https://vili.dev>

if command -v plasmoidviewer &>/dev/null; then
    echo "Launching plasmoidviewer..."
    plasmoidviewer -a package/
else
    echo "plasmoidviewer is missing, make sure you have the plasma-sdk installed..!"
fi
