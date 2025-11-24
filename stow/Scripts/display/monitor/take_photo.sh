#!/bin/bash
DEV=/dev/video0
OUT="snapshot_$(date +%s).jpg"

v4l2-ctl \
  --device="$DEV" \
  --set-fmt-video=width=1280,height=720,pixelformat=MJPG \
  --stream-mmap \
  --stream-to="$OUT" \
  --stream-count=1

