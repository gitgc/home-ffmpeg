# home-ffmpeg

personal ffmpeg helper scripts

## timelapse.sh

Creates a timelapse video from a directory of images. The images must be named in a sequential order (e.g., img001.jpg, img002.jpg, etc.).

```bash
    ./timelapse.sh /path/to/images width height fps output_video.mp4

    # e.g.

    ./timelapse.sh /home/user/timelapse_images 1920 1080 30 timelapse.mp4
```
