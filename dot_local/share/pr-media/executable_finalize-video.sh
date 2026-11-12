#!/usr/bin/env bash
# Usage: finalize-video.sh <in.webm|in.mov|in.mp4> <out.mp4>
# Converts a Playwright or iOS Simulator recording to an H.264 mp4 played at 1.5x,
# at most 1280 px tall, under 10 MB.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $(basename "$0") <in.webm|in.mov|in.mp4> <out.mp4>" >&2
  exit 2
fi

in=$1
out=$2
max_bytes=$((10 * 1024 * 1024))

for crf in 26 30 34 38; do
  ffmpeg -loglevel error -y -i "$in" \
    -filter:v "setpts=PTS/1.5,scale=-2:'min(1280,ih)'" -an \
    -c:v libx264 -preset slow -crf "$crf" -pix_fmt yuv420p -movflags +faststart \
    "$out"
  size=$(stat -c %s "$out" 2>/dev/null || stat -f %z "$out")
  if (( size <= max_bytes )); then
    echo "$out: $((size / 1024)) KB (crf $crf, 1.5x)"
    exit 0
  fi
done

echo "$out is still over 10 MB at crf 38: record a shorter flow" >&2
exit 1
