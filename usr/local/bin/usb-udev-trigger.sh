#!/usr/bin/env bash
set -euo pipefail
ACTION=$1
LABEL=$2
USERNAME=$(loginctl list-sessions | awk '$4 == "seat0" {print $3}')

if [[ -z "${USERNAME}" ]]; then
    echo "No active session on seat0, skip"
    exit 0
fi

if [[ -z "${ACTION}" ]]; then
    echo "Unknown action: ${ACTION}"
    exit 1
fi

systemctl --user -M "${USERNAME}@" start usb-notify@${ACTION}:${LABEL}.service
