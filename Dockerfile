FROM ubuntu:latest

# "Single command for python 3 and qt5" from https://wiki.freecadweb.org/Compile_on_Linux#Debian_and_Ubuntu
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cmake cmake-gui libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-graph-dev libboost-iostreams-dev libboost-program-options-dev libboost-python-dev libboost-regex-dev libboost-serialization-dev libboost-thread-dev libcoin-dev libeigen3-dev libgts-bin libgts-dev libkdtree++-dev libmedc-dev libocct-data-exchange-dev libocct-ocaf-dev libocct-visualization-dev libopencv-dev libproj-dev libpyside2-dev libqt5opengl5-dev libqt5svg5-dev libqt5webkit5-dev libqt5x11extras5-dev libqt5xmlpatterns5-dev libshiboken2-dev libspnav-dev libvtk7-dev libx11-dev libxerces-c-dev libzipios++-dev occt-draw pyside2-tools python3-dev python3-matplotlib python3-pivy python3-ply python3-pyside2.qtcore python3-pyside2.qtgui python3-pyside2.qtsvg python3-pyside2.qtwidgets pyqt5-dev-tools qtbase5-dev qttools5-dev swig

# The single command above does not contain this stuff, also from https://wiki.freecadweb.org/Compile_on_Linux#Debian_and_Ubuntu
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  build-essential cmake libtool lsb-release python3 swig

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

