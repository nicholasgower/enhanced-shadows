
#!/usr/bin/env bash
#
# split_shadow.sh
#
# Splits a PNG into two layers:
#   1. "shadow"     - pixels that are pure black (r=g=b) at any alpha,
#                      with alpha rescaled so 50% alpha -> 100% alpha
#                      (i.e. new_alpha = min(1, alpha / 0.5)).
#   2. "foreground" - everything else, i.e. the shadow pixels are made
#                      fully transparent and all other pixels are left
#                      untouched (color + alpha unchanged).
#
# This assumes the source shadow was authored as a solid black shape at
# 50% opacity. Anti-aliased edges of that shape are still pure black
# (r=g=b=0) but with alpha < 50%, so rescaling alpha by 2x (clamped to
# 100%) recovers a clean, fully-opaque black shadow mask.
#
# Usage:
#   ./split_shadow.sh input.png shadow_out.png foreground_out.png [black_threshold]
#
#   black_threshold : optional, 0-1 (default 0).
#                      A pixel is treated as "shadow" if r,g,b are all
#                      <= black_threshold. Use 0 for exact pure-black
#                      matching. Raise slightly (e.g. 0.02) if your
#                      source has compression artifacts or near-black
#                      noise that should still count as shadow.
#
# Requires ImageMagick 7 ("magick" command). For IM6, replace "magick"
# with "convert" throughout.
 
set -euo pipefail
 
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 input.png shadow_out.png foreground_out.png [black_threshold(0-1)]" >&2
  exit 1
fi
 
INPUT="$1"
SHADOW_OUT="$2"
FG_OUT="$3"
THRESH="${4:-0}"
 
if [ ! -f "$INPUT" ]; then
  echo "Error: input file '$INPUT' not found." >&2
  exit 1
fi
 
# Condition for "is a shadow pixel": r, g, b are all <= THRESH (near/pure black),
# regardless of the pixel's current alpha value.
COND="(r<=${THRESH})&&(g<=${THRESH})&&(b<=${THRESH})"
 
# --- Shadow layer ---
# 1. Ensure an alpha channel exists.
# 2. Set alpha: where the pixel is black, rescale alpha (0.5 -> 1.0, clamped);
#    elsewhere, force alpha to 0 (fully transparent).
# 3. Force RGB of the surviving (visible) pixels to pure black for a clean layer.
convert "$INPUT" \
  -alpha on \
  -channel A -fx "${COND} ? (a*2>1?1:a*2) : 0" +channel \
  -channel RGB -evaluate set 0 +channel \
  "$SHADOW_OUT"
 
# --- Foreground layer ---
# Ensure alpha channel exists, then zero out alpha only where the shadow
# condition holds. Everything else (color and alpha) is left untouched.
convert "$INPUT" \
  -alpha on \
  -channel A -fx "${COND} ? 0 : a" +channel \
  "$FG_OUT"
 
echo "Shadow layer written to:     $SHADOW_OUT"
echo "Foreground layer written to: $FG_OUT"
