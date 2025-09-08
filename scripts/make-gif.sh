#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/make-gif.sh -i input.mp4 [-o output.gif] [--start 00:00:02] [--end 00:00:10] [--fps 20] [--width 640] [--no-optimize] [--colors 128]

Converts a short MP4 (screen recording) into a high-quality GIF using ffmpeg palette generation.

Options:
  -i, --input     Path to input MP4/MOV/WebM (required)
  -o, --output    Output GIF path (default: same dir/name as input with .gif)
      --start     Optional start timestamp (e.g., 00:00:02)
      --end       Optional end timestamp (e.g., 00:00:10)
      --fps       Frames per second for GIF (default: 20)
      --width     Output width in pixels, height auto-scales (default: 640)
      --no-optimize  Skip gifsicle optimization step
      --colors    Colors for gifsicle optimization (default: 128)

Examples:
  scripts/make-gif.sh -i capture.mp4
  scripts/make-gif.sh -i capture.mp4 --start 00:00:02 --end 00:00:09 -o kick.gif --fps 18 --width 512
USAGE
}

INPUT=""
OUTPUT=""
START=""
END=""
FPS=20
WIDTH=640
OPTIMIZE=1
COLORS=128

while [[ $# -gt 0 ]]; do
  case "$1" in
  -i | --input)
    INPUT="$2"
    shift 2
    ;;
  -o | --output)
    OUTPUT="$2"
    shift 2
    ;;
  --start)
    START="$2"
    shift 2
    ;;
  --end)
    END="$2"
    shift 2
    ;;
  --fps)
    FPS="$2"
    shift 2
    ;;
  --width)
    WIDTH="$2"
    shift 2
    ;;
  --no-optimize)
    OPTIMIZE=0
    shift
    ;;
  --colors)
    COLORS="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "Error: --input is required" >&2
  usage
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is required. Install it and retry." >&2
  exit 1
fi

if [[ -z "${OUTPUT}" ]]; then
  base="${INPUT%.*}"
  OUTPUT="${base}.gif"
fi

workdir="$(mktemp -d 2>/dev/null || mktemp -d -t gifwork)"
trap 'rm -rf "$workdir"' EXIT

trimmed="$workdir/trimmed.mp4"
palette="$workdir/palette.png"
rawgif="$workdir/raw.gif"

# Prepare input (optionally trim)
if [[ -n "$START" || -n "$END" ]]; then
  args=(-y)
  [[ -n "$START" ]] && args+=(-ss "$START")
  [[ -n "$END" ]] && args+=(-to "$END")
  args+=(-i "$INPUT" -c:v libx264 -preset veryfast -crf 18 -an "$trimmed")
  ffmpeg "${args[@]}"
  SRC="$trimmed"
else
  SRC="$INPUT"
fi

# Generate palette
ffmpeg -y -i "$SRC" -vf "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,palettegen" "$palette"

# Create GIF using palette
ffmpeg -y -i "$SRC" -i "$palette" -lavfi "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,paletteuse=dither=sierra2_4a" "$rawgif"

# Optimize (optional)
if [[ $OPTIMIZE -eq 1 ]]; then
  if command -v gifsicle >/dev/null 2>&1; then
    gifsicle -O3 --colors "$COLORS" "$rawgif" -o "$OUTPUT"
  else
    echo "Note: gifsicle not found; skipping optimization. Install gifsicle to reduce size."
    mv "$rawgif" "$OUTPUT"
  fi
else
  mv "$rawgif" "$OUTPUT"
fi

echo "Created: $OUTPUT"
