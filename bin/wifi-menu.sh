#!/bin/bash
set -euo pipefail

ROFI_CMD=(rofi -dmenu -location 3 -xoffset -20 -yoffset 30 -width 30 -lines 8)
PROMPT_WIFI=("Wi-Fi")
PROMPT_PASS=("Password")
NOTIFY=${NOTIFY_SEND:-notify-send}

pick_iface() {
    if [[ -n "${WIFI_IFACE:-}" ]]; then
        printf '%s' "$WIFI_IFACE"
        return
    fi
    mapfile -t devs < <(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2=="wifi" {print $1":"$3}')
    if [[ ${#devs[@]} -eq 0 ]]; then
        printf ''
        return
    fi
    for entry in "${devs[@]}"; do
        IFS=':' read -r dev state <<<"$entry"
        if [[ "$state" != "unavailable" ]]; then
            printf '%s' "$dev"
            return
        fi
    done
    IFS=':' read -r dev _ <<<"${devs[0]}"
    printf '%s' "$dev"
}

list_networks() {
    local iface="$1"
    nmcli dev wifi rescan ifname "$iface" >/dev/null 2>&1 || true
    nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list ifname "$iface" |
        awk -F: 'length($1) {sig=($2 && $2!="")?$2:"0"; sec=($3 && $3!="")?$3:"open"; printf "%s\t%3s%%\t%s\n", $1, sig, sec}'
}

wifi_menu() {
    local iface="$1"
    local list choice
    list=$(list_networks "$iface")
    if [[ -z "$list" ]]; then
        printf ''
        return
    fi
    choice=$(printf '%s\n' "$list" | ROFI_RETV=0 "${ROFI_CMD[@]}" -p "${PROMPT_WIFI[@]}")
    printf '%s' "$choice"
}

prompt_password() {
    ROFI_RETV=0 "${ROFI_CMD[@]}" -password -p "${PROMPT_PASS[@]}"
}

notify() {
    local msg="$1"
    if command -v "$NOTIFY" >/dev/null 2>&1; then
        "$NOTIFY" "$msg"
    fi
}

main() {
    command -v nmcli >/dev/null 2>&1 || { notify "nmcli not found"; exit 1; }
    command -v rofi >/dev/null 2>&1 || { notify "rofi not found"; exit 1; }

    local iface
    iface=$(pick_iface)
    if [[ -z "$iface" ]]; then
        notify "No Wi-Fi interface"
        exit 1
    fi

    local selection
    selection=$(wifi_menu "$iface")
    if [[ -z "$selection" ]]; then
        exit 0
    fi

    IFS=$'\t' read -r ssid signal security <<<"$selection"
    ssid=$(printf '%s' "$ssid" | sed 's/[[:space:]]*$//')
    if [[ -z "$ssid" ]]; then
        exit 0
    fi

    local password=""
    if [[ "$security" != "open" && "$security" != "--" ]]; then
        password=$(prompt_password)
        [[ -z "$password" ]] && exit 0
    fi

    if [[ -n "$password" ]]; then
        nmcli device wifi connect "$ssid" password "$password" ifname "$iface" >/tmp/wifi-menu.log 2>&1 || { notify "Failed to connect to $ssid"; exit 1; }
    else
        nmcli device wifi connect "$ssid" ifname "$iface" >/tmp/wifi-menu.log 2>&1 || { notify "Failed to connect to $ssid"; exit 1; }
    fi

    notify "Connected to $ssid"
    pkill -RTMIN+1 dwmblocks >/dev/null 2>&1 || true
}

main "$@"
