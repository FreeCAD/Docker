#git clone https://github.com/FreeCAD/FreeCAD.git ../source

fc_source=$(pwd)/../source
fc_build=$(pwd)/../build
other_files=$(pwd)/../yolo
docker run -it --rm \
-v $fc_source:/mnt/source \
-v $fc_build:/mnt/build \
-v $other_files:/mnt/files \
-e "DISPLAY" -e "QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
freecad:latest bash
