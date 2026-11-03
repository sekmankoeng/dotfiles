#!/usr/bin/env bash
case "$1" in
    dark) THEME="prefer-dark" ;;
    light) THEME="prefer-light" ;;
esac

gsettings set org.gnome.desktop.interface color-scheme "$THEME"
