/* modify this file to change what commands output to your statusbar, and
 * recompile using the make command */
static const Block blocks[] = {
	/* command                interval    signal */
	/* No news ticker for admin - just essentials */
	{ "date '+%a, %d %b 󰃭 %H:%M'",            30,      0 },
};

/* sets delimeter between status commands. NULL character ('\0') means no
 * delimeter */
static char delim[] = "\x1f";
