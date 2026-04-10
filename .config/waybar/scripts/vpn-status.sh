#!/usr/bin/env bash

# Check for WireGuard interfaces
wg_active=false
if command -v wg &>/dev/null && wg show interfaces 2>/dev/null | grep -q .; then
    wg_active=true
fi

# Check for tun/tap interfaces (OpenVPN, etc.)
tun_active=false
if ip link show up type tun 2>/dev/null | grep -q .; then
    tun_active=true
fi

if [ "$wg_active" = true ] || [ "$tun_active" = true ]; then
    iface=""
    if [ "$wg_active" = true ]; then
        iface=$(wg show interfaces 2>/dev/null | head -1)
    else
        iface=$(ip link show up type tun 2>/dev/null | head -1 | awk -F: '{print $2}' | tr -d ' ')
    fi
    echo "{\"text\": \"$iface\", \"alt\": \"connected\", \"tooltip\": \"VPN: $iface\", \"class\": \"connected\"}"
else
    echo "{\"text\": \"\", \"alt\": \"disconnected\", \"tooltip\": \"VPN: disconnected\", \"class\": \"disconnected\"}"
fi
