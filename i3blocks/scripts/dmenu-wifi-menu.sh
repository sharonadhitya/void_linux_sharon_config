#!/bin/sh
# --------------------------------------------------------------
#  dmenu Wi-Fi connector – wide password prompt (uses -W only)
# --------------------------------------------------------------

IFACE=wlo1
DMENU="dmenu -b -p"          # base options
DMENU_WIDTH=800              # width in pixels (your working flag)

notify() { notify-send "Wi-Fi Menu" "$1"; }

# ---------- 1. Scan ----------
wpa_cli -i "$IFACE" scan >/dev/null
sleep 2

# ---------- 2. List networks ----------
options=$(wpa_cli -i "$IFACE" scan_results |
          awk 'NR>1 { $1=$2=$3=$4=""; sub(/^[ \t]+/, ""); print }' |
          sort -u)

# ---------- 3. Choose network ----------
chosen_network=$(printf '%s\n' "$options" |
                 $DMENU "Choose Wi-Fi:" -l 15)
[ -z "$chosen_network" ] && exit 0

# ---------- 4. Is it already saved? ----------
net_id=$(wpa_cli -i "$IFACE" list_networks |
         grep -F "$chosen_network" | awk '{print $1}')

if [ -n "$net_id" ]; then
    notify "Connecting to saved network: $chosen_network"
    wpa_cli -i "$IFACE" enable_network "$net_id" >/dev/null
    wpa_cli -i "$IFACE" reconnect >/dev/null
    sleep 4
    if wpa_cli -i "$IFACE" status | grep -q "wpa_state=COMPLETED"; then
        notify "Connected!"
    else
        notify "Failed to reconnect."
    fi
    exit 0
fi

# ---------- 5. NEW NETWORK – wide password prompt ----------
#   -W <width>  → wide window
#   empty input → open network
#   cancel      → abort
password=$(printf '' |
           $DMENU "$chosen_network Password (blank = open):" -W "$DMENU_WIDTH")
[ $? -ne 0 ] && { notify "Cancelled."; exit 0; }

# ---------- 6. Add the network ----------
notify "Adding network: $chosen_network"
new_id=$(wpa_cli -i "$IFACE" add_network)
wpa_cli -i "$IFACE" set_network "$new_id" ssid "\"$chosen_network\"" >/dev/null

if [ -z "$password" ]; then
    wpa_cli -i "$IFACE" set_network "$new_id" key_mgmt NONE >/dev/null
    notify "Open network added."
else
    wpa_cli -i "$IFACE" set_network "$new_id" psk "\"$password\"" >/dev/null
    notify "Password saved."
fi

wpa_cli -i "$IFACE" enable_network "$new_id" >/dev/null
wpa_cli -i "$IFACE" reconnect >/dev/null

sleep 5
if wpa_cli -i "$IFACE" status | grep -q "wpa_state=COMPLETED"; then
    notify "Connected! Saving config."
    wpa_cli -i "$IFACE" save_config >/dev/null
else
    notify "Failed. Removing profile."
    wpa_cli -i "$IFACE" remove_network "$new_id" >/dev/null
fi
