This is a docker container intended to act as a build and run environment for
FreeCAD.

The directories containing FreeCAD's source code and build are not included
inside the docker image. Instead, they are attached to the docker container
when you run the container. This allows the built code to have continuity
across different docker containers, reducing the time for a build to occur, and
allowing you to use your own editor/IDE outside of the container.

# Image use

## Pull image

```
docker pull registry.gitlab.com/daviddaish/freecad_docker_env:latest
```

## Run image

Allow xhost access, so you can use the GUI. Note that this method is easy, [but
insecure](https://wiki.ros.org/docker/Tutorials/GUI).

```
xhost +
```

Using enviroment variables, specify:

- The root directory of the FreeCAD source;
- Where to build FreeCAD;
- A directory containing any other files you'd like to use, such as
  `.fcstd` files, for testing.

```
fc_source=~/code/freecad_source
fc_build=~/code/freecad_build
other_files=~/
```

Run the docker image.

```
docker run -it --rm \
-v $fc_source:/mnt/source \
-v $fc_build:/mnt/build \
-v $other_files:/mnt/files \
-e "DISPLAY" -e "QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
registry.gitlab.com/daviddaish/freecad_docker_env:latest
```

You will be able to find the mounted directories within the container in the
`/mnt` directory, named `/mnt/source`, `/mnt/build`, and `/mnt/files`.

## Build FreeCAD

```
/root/build_script.sh
```

## Run FreeCAD

```
/mnt/build/bin/FreeCAD
```

# Developing the image

## Build docker image

Building the docker image will take several hours.

```
docker build -t registry.gitlab.com/daviddaish/freecad_docker_env:latest .
```

Note that, because of the size of the dependancies, docker may throw a `no
space left on device` error part way through the build. To reduce the
likelyhood of this, ensure you have around 25GB of space on your storage, and
running `docker system prune`.

## Pushing the docker image

Prior to pushing, the image must be able to reliabily build the most recent
tags of the FreeCAD source code: `master`, `0.19_pre`, and `0.18.4`.

```
docker login registry.gitlab.com
docker push registry.gitlab.com/daviddaish/freecad_docker_env:updates
```
