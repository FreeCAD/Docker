FROM debian:stretch

SHELL ["/bin/bash", "-c"]

WORKDIR /tmp

# Build tools, and misc supporting tools
RUN apt update && \
    apt install -y build-essential gfortran automake bison flex libtool git \
    wget unzip doxygen

# Python v3.7.6
RUN apt install -y zlib1g-dev libffi-dev libssl-dev && \
    wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tar.xz && \
    tar -xf Python-3.7.6.tar.xz && rm Python-3.7.6.tar.xz && \
    mkdir /tmp/Python-3.7.6/build && cd /tmp/Python-3.7.6/build && \
    ../configure --enable-shared \ 
    --enable-unicode=ucs4 --enable-ipv6 && \
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2) && \
    ldconfig && \
    rm -rfv /tmp/*

# Ensuring Python3.7 is the default version
RUN ln -sf /usr/local/bin/python3.7 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.7-config /usr/local/bin/python-config && \
    # Ensuring python is found, even when program is not looking for "m" suffix
    ln -s python3.7m /usr/local/include/python3.7 && \
    ln -s libpython3.7m.a /usr/local/lib/python3.7/config-3.7m-x86_64-linux-gnu/libpython3.7.a

# CMake v3.16.3
RUN git clone  --verbose -n https://gitlab.kitware.com/cmake/cmake.git && \
    mkdir /tmp/cmake/build && cd /tmp/cmake/build && \
    git checkout v3.16.3 && \
    # I may want to revert to an earlier version to see if the list concatenating
    # issue encountered with Pivy remains.
    ../bootstrap --parallel=$(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) && \
    make install -j $(nproc --ignore=2) && \
    rm -rfv /tmp/*

# Boost v1.72.0
RUN wget https://dl.bintray.com/boostorg/release/1.72.0/source/boost_1_72_0.tar.gz && \
    tar -xzf boost_1_72_0.tar.gz && rm boost_1_72_0.tar.gz && \
    cd /tmp/boost_1_72_0 && \
    ./bootstrap.sh --with-python=/usr/local/bin/python3 \
    --with-python-root=/usr/local --with-python-version=3.7 && \
    ./b2 -j$(nproc --ignore=2) && \
    ./b2 -j$(nproc --ignore=2) install && \
    rm -rf /tmp/*

# Link libboost_python, so it can be found without it's python version
RUN ln -s /usr/local/lib/libboost_python37.so.1.72.0 /usr/local/lib/libboost_python.so  

# Infrequently used languages
RUN apt install -y perl ruby

# Freetype v 2.9.1
RUN wget http://mirror.downloadvn.com/nongnu/freetype/freetype-2.9.1.tar.gz && \
    tar -xzf freetype-2.9.1.tar.gz && rm freetype-2.9.1.tar.gz && \
    cd  /tmp/freetype-2.9.1 && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# QT5's accessability dependancies, webkit dependancies, multimedia
# dependancies, and Libxcb
RUN apt install -y libatspi2.0-dev libdbus-1-dev flex gperf libicu-dev \
    libxslt-dev ruby bison libasound2-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev '^libxcb.*-dev' libx11-xcb-dev \
    libglu1-mesa-dev libxrender-dev libxi-dev libxcb-xinerama0-dev \
    libfontconfig1-dev libx11-dev libxext-dev libxfixes-dev libxcb1-dev \
    libxkbcommon-dev

# QT5 v5.13.2
RUN QT_VER=5.13.2 && \
    git clone -n git://code.qt.io/qt/qt5.git && \
    cd /tmp/qt5 && git checkout $QT_VER && \
    perl init-repository --module-subset=default,-qtpurchasing,\
-qtgamepad,-qtfeedback,-qtandroidextras && \
    ./configure -opensource -confirm-license -qt-xcb \
    -nomake examples -nomake tests && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/* && \
    ln -v -s /usr/local/Qt-$QT_VER /usr/local/Qt-5
ENV PATH="/usr/local/Qt-5/bin:${PATH}"

# QT Wayland v5.14.0
RUN apt install -y libwayland-dev libwayland-egl1-mesa libwayland-server0 \
    libgles2-mesa-dev libxkbcommon-dev && \
    git clone -n git://code.qt.io/qt/qtwayland.git && \
    cd qtwayland && git checkout v5.13.2 &&\
    qmake && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# QT WebKit v5.212
RUN apt install -y libsqlite3-dev libhyphen-dev libjpeg-dev libwebp-dev \
    libxcomposite-dev python2.7 && \
    git clone -n https://code.qt.io/qt/qtwebkit.git && \
    cd /tmp/qtwebkit && git checkout 5.212 && \
    mkdir /tmp/qtwebkit/build && cd build && \
    cmake -D PORT=Qt -D CMAKE_BUILD_TYPE=Release -D ENABLE_ALLINONE_BUILD=OFF .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Clang v9.0.1
RUN git clone -n https://github.com/llvm/llvm-project.git && \
    cd /tmp/llvm-project && git checkout llvmorg-9.0.1 && \
    mkdir /tmp/llvm-project/build && cd /tmp/llvm-project/build && \
    cmake -DLLVM_ENABLE_PROJECTS=clang -G "Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release ../llvm && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# TCL v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tcl8.7a1-src.tar.gz && \
    tar -xzf tcl8.7a1-src.tar.gz && rm tcl8.7a1-src.tar.gz && \
    cd /tmp/tcl8.7a1/unix && \
    ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# TK v8.7
RUN wget https://prdownloads.sourceforge.net/tcl/tk8.7a1-src.tar.gz && \
    tar -xzf tk8.7a1-src.tar.gz && rm tk8.7a1-src.tar.gz && \
    cd /tmp/tk8.7a1/unix && \
    ./configure --enable-64bit --enable-shared --enable-gcc --enable-threads && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Open Cascade v7.4
RUN apt install -y libxt-dev libxmu-dev libxi-dev libgl1-mesa-dev \
    libglu1-mesa-dev libfreeimage-dev libtbb-dev && \
    wget "http://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=fd47711d682be943f0e0a13d1fb54911b0499c31;sf=tgz" -O occt.tar.gz && \
    mkdir /tmp/occt && \
    tar -xzf occt.tar.gz -C /tmp/occt --strip-components 1 && \
    mkdir /tmp/occt/build && cd /tmp/occt/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Gmsh v4.5.1
RUN wget gmsh.info/src/gmsh-4.5.1-source.tgz && \
    tar -xzf gmsh-4.5.1-source.tgz && rm gmsh-4.5.1-source.tgz && \
    mkdir /tmp/gmsh-4.5.1-source/build && cd /tmp/gmsh-4.5.1-source/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Coin 3D v2020/1/25
RUN git clone -n https://github.com/coin3d/coin.git && \
    cd /tmp/coin && git checkout 381b9acb29243d7e381106dbebb98f11681c10e5 && \
    mkdir /tmp/coin/build_tmp && cd /tmp/coin/build_tmp && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Swig v4.0.1
RUN apt install -y libpcre3-dev && \
    wget https://cfhcable.dl.sourceforge.net/project/swig/swig/swig-4.0.1/swig-4.0.1.tar.gz && \
    tar -xzf swig-4.0.1.tar.gz && rm swig-4.0.1.tar.gz && \
    cd /tmp/swig-4.0.1 && \
    ./configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# SOQT v1.5.0
RUN git clone -n https://github.com/coin3d/soqt.git && \
    cd /tmp/soqt && git checkout 2d0e3ed22f942d51380e1f8e67289b9eb6732f67 && \
    git submodule update --init --recursive && \
    mkdir /tmp/soqt/build_tmp && cd /tmp/soqt/build_tmp && \
    cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-5 .. && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Pivy v0.6.5
RUN apt install -y gcc-multilib g++-multilib && \
    git clone -n https://github.com/coin3d/pivy.git && \
    cd /tmp/pivy && git checkout 0.6.5 && \
    rm setup.py
ADD add_files/pivy_setup.py /tmp/pivy/setup.py
RUN cd /tmp/pivy && \
    export CMAKE_PREFIX_PATH=/usr/local/Qt-5 && \
    CFLAGS="-fpermissive" python3 setup.py build && \
    python3 setup.py install && \
    rm -rfv /tmp/*
# There are four issues I ran into with the Pivy setup.py script while I was
# creating this Dockerfile. I am documenting the issues here, so I can resolve
# them in a less hacky way, later.
# 1) SWIG -I flags
#    SWIG needs to be given the following additional flags:
#    -I/usr/include/boost/compatibility/cpp_c_headers
#    -I/usr/include/x86_64-linux-gnu/c++/6/ 
#    -I/usr/include/c++/6
# 2) Finding qmake
#    The script cannot find the qmake binary, so when running:
#    `qtinfo.QtInfo()`, add this argument:
#    `qtinfo.QtInfo(qmake_command=['/usr/local/Qt-5/bin/qmake'])`
# 3) CMake misreporting SoQt include dirs
#    For some reason, CMake reports the SOQT_INCLUDE_DIR as
#    `/usr/local/include/usr/include`, instead of
#    `/usr/local/include;/usr/include`. I'm not entirely sure why. To work
#    around that, overwrite the stored value like this:
#    `config_dict["SOQT_INCLUDE_DIR"] = "/usr/local/include"`
# 4) -fpermissive flag
#    I ran into the following issue when the swig-generated file coin_wrap.cpp
#    got compiled. This forced me to add the -fpermissive flag to the
#    compilation. While I'm not an expert, it is my understanding this is
#    unsafe:
#    pivy/coin_wrap.cpp: In function ‘void SoSensorPythonCB(void*, SoSensor*)’:
#    pivy/coin_wrap.cpp:6342:40: warning: invalid conversion from ‘const char*’ to ‘char*’ [-fpermissive]
#         sensor_cast_name = PyUnicode_AsUTF8(item);
#                            ~~~~~~~~~~~~~~~~^~~~~~
#    pivy/coin_wrap.cpp: In function ‘void SoMarkerSet_addMarker__SWIG_3(int, const SbVec2s&, PyObject*, SbBool, SbBool)’:
#    pivy/coin_wrap.cpp:7236:43: warning: invalid conversion from ‘const char*’ to ‘char*’ [-fpermissive]
#                 coin_marker = PyUnicode_AsUTF8(string);
#                               ~~~~~~~~~~~~~~~~^~~~~~~~

# simage v1.8.0
RUN git clone -n https://github.com/coin3d/simage.git && \
    cd /tmp/simage && git checkout simage-1.8.0 && \
    git submodule update --init --recursive && \   
    mkdir /tmp/simage/tmp_build && cd /tmp/simage/tmp_build && \
    ../configure && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Eigen v3.3.7
RUN git clone -n https://gitlab.com/libeigen/eigen.git && \
    cd /tmp/eigen && git checkout 3.3.7 && \
    mkdir /tmp/eigen/build && cd /tmp/eigen/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# LibArea v12/7/2015
RUN git clone -n https://github.com/danielfalck/libarea.git && \
    cd /tmp/libarea && git checkout 51e6778 && \
    mkdir /tmp/libarea/build && cd /tmp/libarea/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Xerces C++ v3.2.2
RUN wget https://www-eu.apache.org/dist//xerces/c/3/sources/xerces-c-3.2.2.tar.gz && \
    tar -xzf xerces-c-3.2.2.tar.gz && rm xerces-c-3.2.2.tar.gz && \
    mkdir /tmp/xerces-c-3.2.2/build && cd /tmp/xerces-c-3.2.2/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Pyside2 and shiboken2 v5.13.2
RUN git clone -n https://code.qt.io/pyside/pyside-setup && \
    cd /tmp/pyside-setup && git checkout v5.13.2 && \
    git submodule update --init --recursive --progress && \
    python setup.py install --cmake=/usr/local/bin/cmake \
    --qmake=/usr/local/Qt-5/bin/qmake --ignore-git \
    --parallel=$(nproc --ignore=2) && \
    # Create links to make it easier to point Freecad's CMAKE script to the
    # shared libraries.
    cd /usr/local/lib/python3.7/site-packages && \
    ln -s libshiboken2.cpython-37m-x86_64-linux-gnu.so.5.13 \
    shiboken2/libshiboken2.cpython-37m-x86_64-linux-gnu.so.5 && \
    ln -s libpyside2.cpython-37m-x86_64-linux-gnu.so.5.13 \
    PySide2/libpyside2.cpython-37m-x86_64-linux-gnu.so.5 && \
    rm -rfv /tmp/*

# IFC Open Shell v0.6.0b0
RUN git clone -n https://github.com/IfcOpenShell/IfcOpenShell.git && \
    cd /tmp/IfcOpenShell && git checkout v0.6.0b0 && \
    mkdir /tmp/IfcOpenShell/build && cd /tmp/IfcOpenShell/build && \
    cmake ../cmake -D COLLADA_SUPPORT=0 \
    -D OCC_INCLUDE_DIR=/usr/local/include/opencascade \
    -D OCC_LIBRARY_DIR=/usr/local/lib \
    -D LIBXML2_LIBRARIES=/usr/lib/x86_64-linux-gnu/libxml2.so \
    -D LIBXML2_INCLUDE_DIR=/usr/include/libxml2 && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# Numpy v1.16.2 and Matplotlib v3.0.3
RUN python -m pip install cython==0.29.14 && python -m pip install numpy==1.18.1 matplotlib==3.1.2

# SPOOLES v2.2
RUN mkdir spooles && cd spooles && \
    wget www.netlib.org/linalg/spooles/spooles.2.2.tgz && \
    tar -xzf spooles.2.2.tgz && \
    make lib CC=cc -j $(nproc --ignore=2) && \
    mkdir /usr/local/SPOOLES.2.2 && \
    mv * /usr/local/SPOOLES.2.2 && \
    rm -rfv /tmp/*

# ARpack v96
RUN mkdir arpack && cd arpack && \
    wget https://www.caam.rice.edu/software/ARPACK/SRC/arpack96.tar.gz && \
    wget https://www.caam.rice.edu/software/ARPACK/SRC/patch.tar.gz && \
    tar -xzf arpack96.tar.gz && \
    tar -xzf patch.tar.gz && \
    cd ARPACK && \
    sed -i 's/      EXTERNAL           ETIME/*     EXTERNAL           ETIME/' UTIL/second.f && \
    make lib home=/tmp/arpack/ARPACK MAKE=make SHELL=bash FC=gfortran PLAT=INTEL FFLAGS="-O"  && \
    mkdir /usr/local/ARPACK && \
    mv libarpack_INTEL.a /usr/local/ARPACK && \
    rm -rfv /tmp/*

# CalculiX v2.16
RUN cd /usr/local && \
    wget http://www.dhondt.de/ccx_2.16.src.tar.bz2 && \
    tar -xjvf ccx_2.16.src.tar.bz2 && \
    cd /usr/local/CalculiX/ccx_2.16/src && \
    make -j $(nproc --ignore=2)&& \
    mv ccx_2.16 /usr/local/bin/ccx && \
    cd /usr/local/bin && \
    chmod a+rx ccx

# VTK v8.2.0
RUN git clone -n https://gitlab.kitware.com/vtk/vtk.git && \
    mkdir /tmp/vtk/build && cd /tmp/vtk/build && \
    git checkout v8.2.0 && \
    cmake -DVTK_QT_VERSION:STRING=5 \
    -D QT_QMAKE_EXECUTABLE:PATH=/usr/local/Qt-5.12.6/bin/qmake \
    -D VTK_Group_Qt:BOOL=ON \
    -D CMAKE_PREFIX_PATH:PATH=/usr/local/Qt-5/lib/cmake  \
    -D BUILD_SHARED_LIBS:BOOL=ON \
    .. && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# HDF5 v1.10.6 (CMake version)
ENV hdf5_path=/usr/local/hdf5
RUN wget https://hdf-wordpress-1.s3.amazonaws.com/wp-content/uploads/manual/HDF5/HDF5_1_10_6/source/CMake-hdf5-1.10.6.tar.gz && \
    tar -xzf CMake-hdf5-1.10.6.tar.gz && \
    cd CMake-hdf5-1.10.6 && \
    ./build-unix.sh && \
    ./HDF5-1.10.6-Linux.sh --exclude-subdir --skip-license && \
    mkdir $hdf5_path && \
    mv HDF_Group/HDF5/1.10.6/* $hdf5_path && \
    export PATH=$PATH:$hdf5_path && \
    echo "$hdf5_path/lib" > /etc/ld.so.conf.d/hdf5.conf && \
    ldconfig && \
    # Because HDF5's libz.so does not have version information, link to use
    # package installed version.
    rm /usr/local/hdf5/lib/libz.so* && \
    ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/local/hdf5/lib/libz.so && \
    ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/local/hdf5/lib/libz.so.1 && \
    ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/local/hdf5/lib/libz.so.1.2.11 && \
    rm -rfv /tmp/* 

# HDF5's root has to be on the path for it to be detected.
ENV PATH=$PATH:$hdf5_path

# Libmed v3.0.6-11 (AKA: MED-fichier/Modelisation and Data Exchange)
RUN wget https://salsa.debian.org/science-team/med-fichier/-/archive/debian/4.0.0+repack-9/med-fichier-debian-4.0.0+repack-9.tar.gz && \
    tar -xzf med-fichier-debian-4.0.0+repack-9.tar.gz && \
    rm med-fichier-debian-4.0.0+repack-9.tar.gz && \
    mkdir /tmp/med-fichier-debian-4.0.0+repack-9/build && \
    cd /tmp/med-fichier-debian-4.0.0+repack-9/build && \
    cmake .. && \
    make -j $(nproc --ignore=2) && make -j $(nproc --ignore=2) install && \
    rm -rfv /tmp/*

# OpenCamLib v29/12/2019(Commit:983a4168fb0a8e84154c45c6f0a286dc2e752b9a)
RUN git clone -n https://github.com/aewallin/opencamlib.git && \
    mkdir /tmp/opencamlib/build && cd /tmp/opencamlib/build && \
    git checkout 983a4168fb0a8e84154c45c6f0a286dc2e752b9a && \
    cmake -D BUILD_PY_LIB=ON -D BUILD_CXX_LIB=OFF -D USE_PY_3=ON ../src && \
    make -j $(nproc --ignore=2) && \
    make -j $(nproc --ignore=2) install

# Add the build script
ADD add_files/freecad_build_script.sh /root/build_script.sh

# Add enviroment varaible so CMake can find QT5
ENV CMAKE_PREFIX_PATH=/usr/local/Qt-5

# So Qt5 can find it's shared libaries
RUN echo "/usr/local/Qt-5/lib" > /etc/ld.so.conf.d/qt5.conf && \
    ldconfig

WORKDIR /root

# Note for later: May need -fPIC
