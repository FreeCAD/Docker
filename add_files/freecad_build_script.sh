#!/bin/bash

set -e

cmake -j$(nproc) \
    -D BOOST_ROOT=/usr/local/include/boost \
    -D BUILD_QT5=ON -D BUILD_FEM=ON -D BUILD_SANDBOX=ON \
    -D PYTHON_LIBRARY=/usr/local/lib/libpython3.7m.so \
    -D PYTHON_INCLUDE_DIR=/usr/local/include/python3.7 \
    -D PYTHON_PACKAGES_PATH=/usr/local/lib/python3.7/site-packages \
    -D PYTHON_EXECUTABLE=/usr/local/bin/python3 \
    -D SHIBOKEN_INCLUDE_DIR=/usr/local/lib/python3.7/site-packages/shiboken2_generator/include \
    -D SHIBOKEN_LIBRARY=/usr/local/lib/python3.7/site-packages/shiboken2/libshiboken2.cpython-37m-x86_64-linux-gnu.so.5 \
    -D PYSIDE_INCLUDE_DIR=/usr/local/lib/python3.7/site-packages/PySide2/include \
    -D PYSIDE_LIBRARY=/usr/local/lib/python3.7/site-packages/PySide2/libpyside2.cpython-37m-x86_64-linux-gnu.so.5 \
    -D PYSIDE2RCCBINARY=/usr/local/lib/python3.7/site-packages/PySide2/pyside2-rcc \
    -S /mnt/source \
    -B /mnt/build

cd /mnt/build

make -j $(nproc)
