dwmblocks
=========
Modular status bar for dwm written in c.

Installation
------------
Edit config.mk to match your local setup (dwmblocks is installed into the
/usr/local namespace by default).

Afterwards enter the following command to build and install slock
(if necessary as root):

    make clean install

Updating dwmblocks
------------------
After making changes to scripts or config:

1. Rebuild and install: `sudo make clean install`
2. Clear any cached block output (e.g., `rm ~/.cache/dwmblocks/*`)
3. Restart dwmblocks: `pkill dwmblocks && dwmblocks &`

Icons
-----
The status icons (weather symbols, etc.) require Nerd Fonts Symbols:

    sudo pacman -S ttf-nerd-fonts-symbols

Common icons used:
- `󰖐` cloudy, `󰖗` rain/umbrella, `󰖘` snow
- `󰖙` sunny, `󰖕` partly cloudy, `󰖝` windy

Running dwm
-----------
Add the following line to your .xinitrc to start dwmblocks using startx:

    dwmblocks &

Or run the 'dwmblocks' command.

News ticker helper
-------------------
The `bin/news-ticker.sh` script expects to run continuously so it can update
`~/.cache/dwmblocks/news` and ping dwmblocks with `SIGRTMIN+5`. To keep it
alive across lid closes and reboots, ship the included user-level systemd
unit:

```
./scripts/install-news-ticker.sh
```

The helper copies `systemd/news-ticker.service` into
`$XDG_CONFIG_HOME/systemd/user/`, reloads `systemctl --user`, and enables the
service immediately. Re-run the installer on any new machine after deploying
this repo to ensure the ticker comes up automatically.

