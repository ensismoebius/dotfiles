#!/usr/bin/env bash
# pure bash marquee for waybar (no temp files)
MAX=${MAX:-25}    # visible chars
SPEED=${SPEED:-3} # chars per second
PAD="   "         # trailing padding for nicer wrap

# ensure a UTF-8 locale so bash length/substr work on characters
# user system must have a UTF-8 locale available; do NOT override if user set LC_* externally
: "${LANG:=pt_BR.UTF-8}"
export LANG

json_escape() {
  # escape backslash, double quote and map newlines to spaces
  local s="$1"
  s="${s//$'\\'/\\\\}"   # \ -> \\
  s="${s//\"/\\\"}"      # " -> \"
  s="${s//$'\n'/ }"      # newline -> space
  printf '%s' "$s"
}

PLAYER_LIST=$(playerctl -l 2>/dev/null || true)
[ -z "$PLAYER_LIST" ] && { echo '{"text": ""}'; exit 0; }

STATUS=$(playerctl status 2>/dev/null || true)
META=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true)
[ -z "$META" ] && { echo '{"text": ""}'; exit 0; }

s="${META}${PAD}"
# normalize newlines to space
s="${s//$'\n'/ }"

# character length (bash counts characters with proper locale)
n=${#s}
if [ "$n" -le "$MAX" ]; then
  window="$s"
else
  # offset based on current epoch seconds * speed
  now=$(date +%s)
  offset=$(( (now * SPEED) % n ))

  # if window fits without wrap
  if [ $((offset + MAX)) -le "$n" ]; then
    window="${s:offset:MAX}"
  else
    part1="${s:offset}"
    # compute remainder length needed (MAX - length(part1))
    len1=${#part1}
    need=$((MAX - len1))
    part2="${s:0:need}"
    window="${part1}${part2}"
  fi
fi

ESCAPED=$(json_escape "$window")
CLS=""
[ "$STATUS" = "Playing" ] && CLS='"class":"playing",'
[ "$STATUS" = "Paused"  ] && CLS='"class":"paused",'

echo "{$CLS\"text\": \"$ESCAPED\"}"
