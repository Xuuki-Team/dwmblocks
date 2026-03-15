/* modify this file to change what commands output to your statusbar, and
 * recompile using the make command */
static const Block blocks[] = {
	/* command                interval    signal */
	{ "date '+%a %b %d 󰃭 %H:%M'",            30,      0 },
        { "$HOME/dwmblocks/wifi.sh",            5,        1 },
};

/* sets delimeter between status commands. NULL character ('\0') means no
 * delimeter */
static char delim[] = "";
