#!/usr/bin/env bash

# --- Original adjust_brigthness.sh logic ---
DEV=/dev/video0
# choose mapping curve (gamma) to taste
GAMMA=0.5

# Function to check if a camera is in use by another process
is_camera_in_use() {
    # lsof /dev/video* will list open files in /dev/video*, which are camera devices.
    # We use pgrep -P $$ to find child processes of the current script,
    # and then use grep -v -f <(pids) to exclude them from the lsof output.
    # This prevents the script from deadlocking by detecting its own ffmpeg process.
    child_pids=$(pgrep -P $$)
    if [ -n "$child_pids" ]; then
        lsof -F p /dev/video* 2>/dev/null | cut -c 2- | grep -v -F -f <(echo "$$"; echo "$child_pids") >/dev/null
    else
        lsof -F p /dev/video* 2>/dev/null | cut -c 2- | grep -v "$$" >/dev/null
    fi
}

while true; do
    # Wait until the camera is no longer in use by other processes
    while is_camera_in_use; do
        # Wait for 10 seconds before checking again
        sleep 10
    done

    # compute perceptual mean luminance [0..1]
    # using ImageMagick: convert to linear gray then measure mean
    # The ffmpeg process will open the camera, but is_camera_in_use() is designed to ignore it.
    L=$(ffmpeg -hide_banner -loglevel error -f v4l2 -video_size "320x240" -i /dev/video0 -frames:v 1 -f image2pipe -vcodec mjpeg - | magick jpeg:- -colorspace sRGB -colorspace Gray -format "%[fx:mean]" info:- 2>/dev/null)

    # L is 0..1
    if [[ -z "$L" ]]; then
      echo "failed to compute luminance, will retry..."
    else
      PERCENT=$(awk -v L="$L" -v g="$GAMMA" 'BEGIN {
        # apply gamma shaping
        p = int( (L**g) * 100 );
        if (p<1) p=1;
        if (p>100) p=100;
        print p;
      }')

      # apply brightness via brightnessctl
      brightnessctl s "$PERCENT%"

      echo "Luminance=$L mapped-> $PERCENT%"
    fi

    # Wait for 5 minutes before the next check
    sleep 300
done