#!/bin/bash

# Configuration
URL="https://www.theguardian.com/uk/rss"
WIDTH=38
REFRESH_FILE="$HOME/.cache/dwm_headlines.cache"
REFRESH_INTERVAL=1800 # 30 minutes

# Function to fetch news
fetch_news() {
    curl -s "$URL" | xmllint --xpath "//item/title/text()" - 2>/dev/null | tr '\n' '  |  '
}

# Initialize cache file if it doesn't exist
if [ ! -f "$REFRESH_FILE" ]; then
    NEWS=$(fetch_news)
    echo "$NEWS" > "$REFRESH_FILE"
    date +%s > "$REFRESH_FILE.time"
fi

# Check if we need to refresh cache
LAST_UPDATE=$(cat "$REFRESH_FILE.time")
NOW=$(date +%s)

if [ $((NOW - LAST_UPDATE)) -ge $REFRESH_INTERVAL ]; then
    NEWS=$(fetch_news)
    echo "$NEWS" > "$REFRESH_FILE"
    date +%s > "$REFRESH_FILE.time"
else
    NEWS=$(cat "$REFRESH_FILE")
fi


# Implement simple scrolling (offset stored in file)
OFFSET_FILE="$HOME/.cache/dwm_headlines.offset"
if [ ! -f "$OFFSET_FILE" ]; then
    echo 0 > "$OFFSET_FILE"
fi

OFFSET=$(cat "$OFFSET_FILE")
NEWS_LEN=${#NEWS}

# Get the substring to display
if [ $OFFSET -ge $NEWS_LEN ]; then
    OFFSET=0
fi
SUBSTR="${NEWS:$OFFSET:$WIDTH}"
if [ ${#SUBSTR} -lt $WIDTH ]; then
    SUBSTR="$SUBSTR${NEWS:0:$((WIDTH - ${#SUBSTR}))}"
fi

# Print to stdout (dwmblocks reads this)
echo "[$SUBSTR  "

# Update offset for next run
NEW_OFFSET=$((OFFSET + 1))
echo $NEW_OFFSET > "$OFFSET_FILE"

