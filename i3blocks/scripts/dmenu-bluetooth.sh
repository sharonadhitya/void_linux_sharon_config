#!/bin/sh
# dmenu script for controlling bluetooth

notify() { notify-send "Bluetooth" "$1"; }

# Main menu options
main_menu="Connect to Device\nTurn On\nTurn Off\nDisconnect Device"

choice=$(echo -e "$main_menu" | dmenu -b -p "Bluetooth Control:" -l 4)

case "$choice" in
    "Connect to Device")
        notify "Scanning for devices..."
        
        # Get list of paired devices
        paired_list=$(bluetoothctl paired-devices)
        paired_names=$(echo "$paired_list" | cut -d' ' -f3- | sort -u)

        # Scan for new devices
        # We run the scan in the background for 8s
        (bluetoothctl scan on > /dev/null & sleep 8; bluetoothctl scan off > /dev/null) &
        
        # Get scanned devices (discoverable)
        scanned_list=$(bluetoothctl devices)
        scanned_names=$(echo "$scanned_list" | cut -d' ' -f3- | sort -u)

        # Combine both lists and show in dmenu
        all_names=$(echo -e "$paired_names\n$scanned_names" | sort -u)
        
        if [ -z "$all_names" ]; then
            notify "No devices found."
            exit
        fi

        chosen_name=$(echo -e "$all_names" | dmenu -b -p "Select device:" -l 15)
        [ -z "$chosen_name" ] && exit
        
        # Get the MAC address for the chosen device
        mac=$( (echo "$paired_list"; echo "$scanned_list") | grep "$chosen_name" | awk '{print $2}' | head -n1)
        
        # Check if the device is already paired
        if echo "$paired_list" | grep -q "$mac"; then
            # --- KNOWN DEVICE ---
            notify "Connecting to paired device $chosen_name..."
            if bluetoothctl connect "$mac"; then
                notify "Connection successful."
            else
                notify "Failed to connect."
            fi
        else
            # --- NEW DEVICE ---
            notify "Pairing with new device $chosen_name..."
            if bluetoothctl pair "$mac"; then
                notify "Pairing successful. Connecting..."
                sleep 1
                if bluetoothctl connect "$mac"; then
                     notify "Connection successful. Trusting device."
                     bluetoothctl trust "$mac"
                else
                    notify "Failed to connect."
                fi
            else
                notify "Pairing failed."
            fi
        fi
        ;;
    "Turn On")
        bluetoothctl power on
        notify "Bluetooth powered on."
        ;;
    "Turn Off")
        bluetoothctl power off
        notify "Bluetooth powered off."
        ;;
    "Disconnect Device")
        # Get list of *connected* devices
        connected_devices=$(bluetoothctl devices Connected | cut -d' ' -f3- | sort -u)
        
        if [ -z "$connected_devices" ]; then
            notify "No devices are connected."
            exit
        fi

        chosen_device=$(echo -e "$connected_devices" | dmenu -b -p "Disconnect from:" -l 5)
        [ -z "$chosen_device" ] && exit
        
        mac=$(bluetoothctl devices Connected | grep "$chosen_device" | awk '{print $2}')
        
        notify "Disconnecting from $chosen_device..."
        bluetoothctl disconnect "$mac"
        ;;
    *)
        exit 0
        ;;
esac
