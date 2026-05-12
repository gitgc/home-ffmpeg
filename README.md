# home-ffmpeg

personal ffmpeg helper scripts. Only tested for me on macOS.

## Requirements

- ffmpeg, installed and on your PATH.

## timelapse.sh

Creates a timelapse video from a directory of images. Sorts images by file created date.

```bash
    ./timelapse.sh /path/to/images width height fps output_video.mp4

    # e.g.

    ./timelapse.sh /home/user/timelapse_images 1920 1080 30 timelapse.mp4
```
