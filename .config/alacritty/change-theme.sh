#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/alacritty/alacritty.toml"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: $CONFIG_FILE does not exist."
    exit 1
fi

if grep -q "gruvbox-light.toml" "$CONFIG_FILE"; then
    sed -i 's/gruvbox-light.toml/gruvbox-dark.toml/' "$CONFIG_FILE"
elif grep -q "gruvbox-dark.toml" "$CONFIG_FILE"; then
    sed -i 's/gruvbox-dark.toml/gruvbox-light.toml/' "$CONFIG_FILE"
else
    echo "No gruvbox theme found to toggle."
    exit 1
fi
