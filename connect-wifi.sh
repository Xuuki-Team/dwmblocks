#!/bin/bash

# Use a terminal prompt for interface, SSID, password
NET_INTERFACE=$(gum choose $(ls /sys/class/net) --cursor-fix)
SSID=$(gum input --prompt "SSID: ")
PASSWORD=$(gum input --password --prompt "Password: ")

# Bring up interface
ip link set $NET_INTERFACE up

# Generate WPA config
wpa_passphrase "$SSID" "$PASSWORD" > /tmp/wpa_supplicant.conf

# Start wpa_supplicant in background
wpa_supplicant -B -i $NET_INTERFACE -c /tmp/wpa_supplicant.conf

# Enable DNS and SSH
systemctl start systemd-resolved
systemctl enable systemd-resolved
systemctl start sshd
systemctl enable sshd
