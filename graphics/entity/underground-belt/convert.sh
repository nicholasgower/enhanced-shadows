#!/bin/bash

# Usage: ./separate_image.sh input.png

INPUT="$1"
BASENAME="${INPUT%.*}"
EXT="${INPUT##*.}"

# Output names
FOREGROUND="${BASENAME}_foreground.${EXT}"
SHADOW="${BASENAME}_shadow.${EXT}"

# === 1. Foreground extraction ===
convert "$INPUT" \
  \( -clone 0 -alpha extract -threshold 95% \) \
  -compose CopyOpacity -composite \
  "$FOREGROUND"

# # === 2. Shadow extraction ===
# # We want to extract areas where alpha ≈ 0.5 (e.g., 0.48–0.52 range)
# # So we'll create a tight bandpass alpha mask

# # Step 1: Extract alpha channel
# convert "$INPUT" -alpha extract "${BASENAME}_alpha.png"

# # Step 2: Create mask where alpha is in the 0.48–0.52 range (~122–132)
# convert "${BASENAME}_alpha.png" \
#   \( +clone -threshold 132 \) \
#   \( +clone -threshold 122 -negate \) \
#   -compose Multiply -composite \
#   "${BASENAME}_shadow_mask.png"

# # Step 3: Create a fully black image with 50% alpha only in the mask area
# convert "${BASENAME}_shadow_mask.png" \
#   -alpha on \
#   -background none \
#   -fill 'rgba(0,0,0,0.5)' \
#   -draw 'color 0,0 reset' \
#   "$SHADOW"

# # Cleanup (optional)
# rm "${BASENAME}_alpha.png" "${BASENAME}_shadow_mask.png"

echo "✅ Foreground saved to: $FOREGROUND"
# echo "✅ Shadow saved to:     $SHADOW"
