#!/usr/bin/env bash
if systemctl is-active --quiet mongodb; then
    sudo systemctl stop mongodb
else
    sudo systemctl start mongodb
fi
