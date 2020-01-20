#!/usr/bin/env bash
# compile openssl, libevent with-openssl, libsodium and libnspv for
# aarch64-linux-android on a macOS Mojave 10.14.6
# Ensure https://developer.android.com/studio/projects/install-ndk
# todo:
# - do we need to split this
# - ndk can be installed from cli

set -xe

SCRIPTPATH=`realpath .`

export ANDROID_API=28
export ARCHITECTURE=android-arm64
export HOST_TAG=darwin-x86_64
export target_host=aarch64-linux-android

export ANDROID_NDK_HOME=${HOME}/Library/Android/sdk/ndk/21.0.6113669
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
export AR=$TOOLCHAIN/bin/aarch64-linux-android-ar
export AS=$TOOLCHAIN/bin/aarch64-linux-android-as
export CC=$TOOLCHAIN/bin/aarch64-linux-android28-clang
export CXX=$TOOLCHAIN/bin/aarch64-linux-android28-clang++
export LD=$TOOLCHAIN/bin/aarch64-linux-android-ld
export RANLIB=$TOOLCHAIN/bin/aarch64-linux-android-ranlib
export STRIP=$TOOLCHAIN/bin/aarch64-linux-android-strip

export PATH=$TOOLCHAIN/bin:$PATH

OPENSSL_VERSION=openssl-1.1.1d
OPENSSL_DIR=$SCRIPTPATH/$OPENSSL_VERSION
OPENSSL_INSTALL_DIR=$SCRIPTPATH/${OPENSSL_VERSION}_install

# openssl
function openssl_install() {
  rm -rf $OPENSSL_INSTALL_DIR $OPENSSL_VERSION
  wget -c https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
  wget -c https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz.sha256
  echo "$(cat ${OPENSSL_VERSION}.tar.gz.sha256) ${OPENSSL_VERSION}.tar.gz" | sha256sum --check --status
  tar xvzf ${OPENSSL_VERSION}.tar.gz
  cd $OPENSSL_DIR
  ./Configure $ARCHITECTURE -D__ANDROID_API__=$ANDROID_API \
    --prefix=$OPENSSL_INSTALL_DIR
  make build_libs
  # Don't install manpages
  make install_sw
}

LIBEVENT_INSTALL_DIR=$SCRIPTPATH/libevent_install

# libevent
function libevent_install() {
  cd $SCRIPTPATH
  rm -rf libevent
  git clone https://github.com/libevent/libevent.git
  cd libevent
  make clean || true

  export PKG_CONFIG_PATH=$OPENSSL_INSTALL_DIR/lib/pkgconfig
  ./autogen.sh

  CPPFLAGS="-I$OPENSSL_INSTALL_DIR/include" \
    LDFLAGS="-L$OPENSSL_INSTALL_DIR/lib" \
    ./configure --host $target_host \
      --prefix=$LIBEVENT_INSTALL_DIR

  make \
    CPPFLAGS="-I$OPENSSL_INSTALL_DIR/include" \
    LDFLAGS="-L$OPENSSL_INSTALL_DIR/lib"
  make install
}

LIBSODIUM_INSTALL_DIR=$SCRIPTPATH/libsodium_install

# Compile and build libsodium
function libsodium_install() {
  cd $SCRIPTPATH
  rm -rf libsodium-stable $LIBSODIUM_INSTALL_DIR
  wget -c https://download.libsodium.org/libsodium/releases/libsodium-1.0.18-stable.tar.gz
  tar xvzf libsodium-1.0.18-stable.tar.gz
  cd libsodium-stable
  export LDFLAGS='--specs=nosys.specs'
  export CFLAGS='-Os'
  ./configure --host=arm-none-eabi --prefix=$LIBSODIUM_INSTALL_DIR
  make
  make install
}

# Compile and build libnspv
function libnspv_install() {
  cd $SCRIPTPATH
  rm -rf libnspv
  git clone https://github.com/dimxy/libnspv.git
  cd libnspv
  git checkout myCC
  ./autogen.sh
  ./configure --enable-androidso \
    --host=$target_host \
    CFLAGS="-I$LIBEVENT_INSTALL_DIR/include -I$LIBSODIUM_INSTALL_DIR/include" \
    LDFLAGS="-L$LIBEVENT_INSTALL_DIR/lib -L$LIBSODIUM_INSTALL_DIR/lib"
  cd src/tools/cryptoconditions
  ./autogen.sh
  ./configure --enable-androidso=yes \
    --host=$target_host \
    CFLAGS="-I$LIBEVENT_INSTALL_DIR/include -I$LIBSODIUM_INSTALL_DIR/include" \
    LDFLAGS="-L$LIBEVENT_INSTALL_DIR/lib -L$LIBSODIUM_INSTALL_DIR/lib"
  make
  cd ../../..
  make
}

openssl_install
libevent_install
libsodium_install
libnspv_install
