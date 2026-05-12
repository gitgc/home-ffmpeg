#!/bin/bash
# This script creates a timelapse video from a series of images.
# Usage: ./timelapse.sh /path/to/images 1920 1080 30 output_video.mp4

set -e

# Check if the correct number of arguments is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 /path/to/images width height fps output_video.mp4"
    exit 1
fi

# Assign arguments to variables
IMAGE_DIR="$1"
WIDTH="$2"
HEIGHT="$3"
FPS="$4"
OUTPUT_VIDEO="$5"

# Check if the image directory exists
if [ ! -d "$IMAGE_DIR" ]; then
    echo "Error: Directory $IMAGE_DIR does not exist."
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install ffmpeg to use this script."
    exit 1
fi

# Collect matching images once so the existence check and ffmpeg input stay in sync.
# Sort by file creation time, then path, so frame order follows the original capture order.
IMAGE_FILES=()
while IFS=$'\t' read -r creation_time image_file; do
    IMAGE_FILES+=("$image_file")
done < <(
    find "$IMAGE_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 |
        while IFS= read -r -d '' image_file; do
            creation_time=$(stat -f '%B' "$image_file")
            printf '%s\t%s\n' "${creation_time:-0}" "$image_file"
        done | LC_ALL=C sort -n -k1,1 -k2,2
)

# Check if there are images in the directory
if [ "${#IMAGE_FILES[@]}" -eq 0 ]; then
    echo "Error: No images found in $IMAGE_DIR. Please add some images to create a timelapse video."
    exit 1
fi

# Check if we can write to the output directory
OUTPUT_DIR=$(dirname "$OUTPUT_VIDEO")
if [ ! -w "$OUTPUT_DIR" ]; then
    echo "Error: Cannot write to directory $OUTPUT_DIR. Please check permissions."
    exit 1
fi

# Create a temporary file to hold the list of images for ffmpeg, and ensure it gets cleaned up on exit
CONCAT_LIST=$(mktemp)
trap 'rm -f "$CONCAT_LIST"' EXIT

# Calculate the duration of each frame based on the specified FPS and write the ffmpeg input list
FRAME_DURATION=$(awk "BEGIN { printf \"%.9f\", 1 / $FPS }")
for image_file in "${IMAGE_FILES[@]}"; do
    escaped_image_file=$(printf '%s' "$image_file" | sed "s/'/'\\\\''/g")
    printf "file '%s'\n" "$escaped_image_file" >> "$CONCAT_LIST"
    printf "duration %s\n" "$FRAME_DURATION" >> "$CONCAT_LIST"
done

# Append the last image again to ensure the final frame is displayed for the correct duration
last_image_index=$((${#IMAGE_FILES[@]} - 1))
last_image_file=${IMAGE_FILES[$last_image_index]}
escaped_last_image_file=$(printf '%s' "$last_image_file" | sed "s/'/'\\\\''/g")
printf "file '%s'\n" "$escaped_last_image_file" >> "$CONCAT_LIST"

# Create the timelapse video using ffmpeg
ffmpeg \
    -f concat \
    -safe 0 \
    -i "$CONCAT_LIST" \
    -fps_mode cfr \
    -r "$FPS" \
    -c:v libx265 \
    -preset fast \
    -crf 35 \
    -pix_fmt yuv420p \
    -tag:v hvc1 \
    -movflags +faststart \
    -vf "scale=$WIDTH:$HEIGHT:force_original_aspect_ratio=decrease,pad=$WIDTH:$HEIGHT:(ow-iw)/2:(oh-ih)/2" \
    "$OUTPUT_VIDEO"

echo "Timelapse video created: $OUTPUT_VIDEO"
