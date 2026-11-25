#!/bin/bash
# wifi-menu.sh — wpa_supplicant native wifi picker (rofi + iw + wpa_cli)
# v2: scans with iw (full results), merges wpa_cli scan_results, picks networks,
#     hides hidden-SSID entries, joins via wpa_cli, renews IP via dhcpcd.
# For the xuuki stack: wpa_supplicant + dhcpcd. Ctrl+W in dwm. Run as root.
set -euo pipefail

IFACE="${WIFI_IFACE:-wlp3s0}"
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"
ROFI_CMD=(rofi -dmenu -location 3 -xoffset -20 -yoffset 30 -width 44 -lines 12)

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need rofi; need wpa_cli; need iw
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

# wpa must be up on $IFACE
if ! wpa_cli -i "$IFACE" ping >/dev/null 2>&1; then
    systemctl start wpa_supplicant; sleep 2
    wpa_cli -i "$IFACE" ping >/dev/null 2>&1 || { echo "wpa_supplicant not on $IFACE" >&2; exit 1; }
fi

# --- Scan (iw gives the full neighbourhood; wpa_cli fills in saved-network ids) ---
wpa_cli -i "$IFACE" scan >/dev/null 2>&1 || true
sleep 3
iw_scan=$(iw dev "$IFACE" scan 2>/dev/null || true)

# gather (ssid, signal-dbm, bssid) from iw; keep entries with a visible SSID
declare -A SIG
while IFS= read -r line; do
    case "$line" in
        *"signal:"*)
            sig=$(printf '%s' "$line" | sed 's/.*signal: \(-\?[0-9.]*\).*/\1/')
            cur_sig=$sig ;;
        *"SSID: "*)
            ssid=${line#*SSID: }
            [[ -z "${ssid// }" ]] && continue
            [[ -n "${SIG[$ssid]:-}" ]] && continue   # strongest BSSID only
            SIG[$ssid]=$cur_sig ;;
    esac
done <<< "$iw_scan"

wpa_list=$(wpa_cli -i "$IFACE" list_networks 2>/dev/null | tail -n +2)

# Build the menu: strongest first
entries=$(for ssid in "${!SIG[@]}"; do printf '%s\t%s\n' "$ssid" "${SIG[$ssid]}"; done | sort -t$'\t' -k2 -rn)
MENU=""
while IFS=$'\t' read -r ssid sig; do
    id=""
    while IFS=$'\t' read -r nid nssid nbsid nflags; do
        [[ "$nssid" == "$ssid" || "$nssid" == "\"$ssid\"" ]] && { id="$nid"; break; }
    done <<< "$wpa_list"
    label="$ssid  ($sig dBm)"
    [[ -n "$id" ]] && label="$label  ★saved"
    MENU+="$ssid"$'\t'"$label"$'\n'
done <<< "$entries"

[[ -n "$MENU" ]] || { echo "no networks found" >&2; exit 0; }

CHOICE=$(printf '%s' "$MENU" | ROFI_RETV=0 "${ROFI_CMD[@]}" -p "Wi-Fi") || exit 0
SSID=$(printf '%s' "$CHOICE" | head -1 | cut -f1)
[[ -n "$SSID" ]] || exit 0

# Saved? select + enable. Not saved? prompt + add.
NETID=""
while IFS=$'\t' read -r nid nssid nbsid nflags; do
    clean=${nssid##\"}; clean=${clean%%\"}
    [[ "$clean" == "$SSID" ]] && { NETID=$nid; break; }
done <<< "$wpa_list"

if [[ -n "$NETID" ]]; then
    wpa_cli -i "$IFACE" disable_network all >/dev/null
    wpa_cli -i "$IFACE" enable_network "$NETID" >/dev/null
    wpa_cli -i "$IFACE" select_network "$NETID" >/dev/null
else
    PASS=$(printf '%s' "$SSID" | ROFI_RETV=0 "${ROFI_CMD[@]}" -password -p "Password") || exit 0
    [[ -n "$PASS" ]] || exit 0
    NETID=$(wpa_cli -i "$IFACE" add_network)
    wpa_cli -i "$IFACE" set_network "$NETID" ssid "\"$SSID\"" >/dev/null
    wpa_cli -i "$IFACE" set_network "$NETID" psk "\"$PASS\"" 2>/dev/null \
      || wpa_cli -i "$IFACE" set_network "$NETID" psk "$(wpa_passphrase "$SSID" "$PASS" | tail -1)" >/dev/null
    wpa_cli -i "$IFACE" disable_network all >/dev/null
    wpa_cli -i "$IFACE" enable_network "$NETID" >/dev/null
    wpa_cli -i "$IFACE" select_network "$NETID" >/dev/null
fi

# persist (conf has update_config=1; fall back to rewrite if save_config denied)
wpa_cli -i "$IFACE" save_config 2>/dev/null | grep -q OK || {
    wpa_cli -i "$IFACE" save_config >/dev/null 2>&1 || true
}

# IP renewal via dhcpcd instance
systemctl restart dhcpcd@"$IFACE" 2>/dev/null || dhcpcd -n "$IFACE"

# wait + report
ip=""
for i in {1..15}; do
    ip=$(ip -4 addr show "$IFACE" | awk '/inet/{print $2}')
    [[ -n "$ip" ]] && break; sleep 1
done
ping -c1 -W3 1.1.1.1 >/dev/null 2>&1 && st="online" || st="no internet yet"
echo "connected: $SSID ($IFACE, ${ip:-no lease}) — $st"
