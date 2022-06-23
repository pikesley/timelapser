FRAMES_PER_SECOND=${1}
TIMESTAMP=$(date +%Y%m%d%H%M%S)

mkdir -p /opt/${PROJECT}/movies/

ffmpeg -pattern_type glob -i "/opt/stills/*.jpg" -c:v libx264 -vf fps=${FRAMES_PER_SECOND} -pix_fmt yuv420p /opt/${PROJECT}/movies/movie-${TIMESTAMP}.mp4
