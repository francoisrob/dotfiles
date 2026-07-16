#!/usr/bin/env bash
# Reports merqube VPN state for the Wayle custom module: "on" when the
# tunnel is up, "off" otherwise. Click handling lives in vpn-toggle.sh.
if nmcli -t -f NAME connection show --active 2>/dev/null | grep -qx merqube; then
    echo "on"
else
    echo "off"
fi
