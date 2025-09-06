#!/bin/bash

# Usage: ./separate_image.sh input.png

INPUT="$1"
BASENAME="${INPUT%.*}"
EXT="${INPUT##*.}"

# Output names
FOREGROUND="${BASENAME}_foreground.${EXT}"
SHADOW="${BASENAME}_shadow.${EXT}"

# Separate the alpha channel
convert "$INPUT" -alpha extract "${BASENAME}_alpha.png"

# Create the foreground: retain pixels with alpha close to 1 (opaque)
# Threshold can be adjusted (e.g., 0.95 for stricter)
convert "$INPUT" \
  \( -clone 0 -alpha extract -threshold 95% \) \
  -compose CopyOpacity -composite \
  "$FOREGROUND"

# Create the shadow: retain pixels where alpha == 0.5
# We'll create a mask where alpha is exactly 50% (127 in 8-bit)
convert "$INPUT" \
  \( -clone 0 -alpha extract -threshold 49% -negate \) \
  \( -clone 0 -alpha extract -threshold 51% \) \
  -compose Multiply -composite \
  -alpha off -compose CopyOpacity -composite \
  "$SHADOW"

echo "Foreground saved to: $FOREGROUND"
echo "Shadow saved to:     $SHADOW"