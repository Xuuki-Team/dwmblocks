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

