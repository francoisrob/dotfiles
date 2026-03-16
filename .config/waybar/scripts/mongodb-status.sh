#!/usr/bin/env bash
if systemctl is-active --quiet mongodb; then
    echo '{"text": "on", "class": "active", "tooltip": "MongoDB is running"}'
else
    echo '{"text": "off", "class": "inactive", "tooltip": "MongoDB is stopped"}'
fi
