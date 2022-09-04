# Script to download, build and install mingw-w64 on a linux host targeting
# an i586 machine.
#
# Used to build a toolchain version for older versions of Windows, targeting
# the Intel Pentium class machines.


#!/bin/bash

NUM_JOBS=24
SYSROOT=/opt/i586-w64-mingw32

# After running this script, put
#
# export PATH=$PATH:$SYSROOT/bin
#
# on your .bashrc

# Abort script if something goes wrong.
set -e


download_packages()
{
  # Download gcc 9.5.0
  wget https://ftp.gnu.org/gnu/gcc/gcc-9.5.0/gcc-9.5.0.tar.xz
  if [ ! -f gcc-9.5.0.tar.xz ]; then
    echo "Error downloading gcc."
    exit 1
  fi

  # Download binutils 2.33.1
  wget https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.xz
  if [ ! -f binutils-2.33.1.tar.xz ]; then
    echo "Error downloading gcc."
    exit 1
  fi

  # Download mingw-w64-v10
  wget https://ufpr.dl.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2
  if [ ! -f mingw-w64-v10.0.0.tar.bz2 ]; then
    echo "Error downloading mingw-w64."
    exit 1
  fi

  # Download pthread-win32
  wget https://ufpr.dl.sourceforge.net/project/pthreads4w/pthreads4w-code-v3.0.0.zip
  if [ ! -f pthreads4w-code-v3.0.0.zip ]; then
    echo "Error downloading pthread-win32"
    exit 1
  fi
}

# Build binutils
build_binutils()
{
  tar -xf binutils-2.33.1.tar.xz
  cd binutils-2.33.1
    mkdir -p build
    cd build
      ../configure --with-sysroot=$SYSROOT --prefix=$SYSROOT --target=i586-w64-mingw32 --disable-multilib
      make -j$NUM_JOBS
      sudo make install
    cd ../
  cd ../

  rm -rf binutils-2.33.1
}

build_gcc()
{
  # Create required directories.
  mkdir -p $SYSROOT/i586-w64-mingw32/lib
  mkdir -p $SYSROOT/i586-w64-mingw32/include

  # Create required syslink.
  ln -s $SYSROOT/i586-w64-mingw32 $SYSROOT/mingw
  ln -s $SYSROOT/i586-w64-mingw32/lib $SYSROOT/i586-w64-mingw32/lib64
  #ln -s $SYSROOT/include $SYSROOT/i586-w64-mingw32/include

  tar -xf gcc-9.5.0.tar.xz
  cd gcc-9.5.0
    mkdir -p build
    cd build
      ../configure --disable-bootstrap --enable-checking=release --enable-languages=c,c++ \
                   --target=i586-w64-mingw32 --disable-multilib \
                   --prefix=$SYSROOT --with-sysroot=$SYSROOT
      make all-gcc -j$NUM_JOBS
      make install-gcc -j$NUM_JOBS
    cd ..
  cd ..

  # Keep the gcc directory for now.
}

build_mingw_headers()
{
  local sysroot=$SYSROOT/i586-w64-mingw32
  tar -xf mingw-w64-v10.0.0.tar.bz2
  cd mingw-w64-v10.0.0/mingw-w64-headers/
    mkdir -p build
    cd build
      ../configure --prefix=$sysroot --build=x86_64-linux-gnu --host=i586-w64-mingw32
      make install -j$NUM_JOBS
    cd ..
  cd ../..
}

build_mingw_crt()
{
  local sysroot=$SYSROOT/i586-w64-mingw32
  cd mingw-w64-v10.0.0/mingw-w64-crt/
    mkdir -p build-crt
    cd build-crt
      ../configure --host=i586-w64-mingw32 --disable-multilib --prefix=$sysroot --with-sysroot=$sysroot

      # compiling in parallel results in error
      make
      make install
    cd ..
  cd ../..

  rm -rf mingw-w64-v10.0.0
}

build_restof_gcc()
{
  cd gcc-9.5.0
    cd build
      make -j$NUM_JOBS
      make install
    cd ..
  cd ..

  rm -rf gcc-9.5.0
}

build_pthreads()
{
  unzip pthreads4w-code-v3.0.0.zip
  cd pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f
    autoconf
    autoheader
    ./configure --prefix=$SYSROOT/i586-w64-mingw32 --host=i586-w64-mingw32
    make clean GC CROSS=i586-w64-mingw32

    # make install is broken
    cp pthreadGC3.dll $SYSROOT/i586-w64-mingw32/lib/
    cp pthreadGC3.dll $SYSROOT/i586-w64-mingw32/lib/libpthread.a
    cp pthread.h $SYSROOT/i586-w64-mingw32/include
    cp sched.h $SYSROOT/i586-w64-mingw32/include
    cp semaphore.h $SYSROOT/i586-w64-mingw32/include
  cd ..

  # Delete build folder.
  rm -rf pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f
}

download_packages

build_binutils

# Temporarly add the SYSROOT/bin into the path
export PATH=$PATH:$SYSROOT/bin

build_mingw_headers

build_gcc

build_mingw_crt

build_restof_gcc

build_pthreads
