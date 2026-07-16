#!/usr/bin/env bash
# Toggles the merqube VPN: down if active, up otherwise. Bound to the
# Wayle custom-vpn module's left-click. Connecting needs the password
# stored on the connection (vpn.secrets), or this silently no-ops.
if nmcli -t -f NAME connection show --active 2>/dev/null | grep -qx merqube; then
    nmcli connection down merqube
else
    nmcli connection up merqube
fi
