sudo modprobe v4l2loopback exclusive_caps=1
ffmpeg -f x11grab -r 30 -s 800x600 -i :0.0+0.0 -vcodec rawvideo -pix_fmt rgb24 -threads 0 -f v4l2 /dev/video0
