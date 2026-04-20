#!/bin/bash
chmod +x ./scripts/utils.bash
source ./scripts/utils.bash
cd ${CURRENT_DIR}



echo "Installing host build tools..."
sudo apt-get update
sudo apt-get install --only-upgrade apt
sudo apt-get install --fix-missing libffi-dev libfontconfig-dev libxrandr-dev libxtst-dev libcups2-dev libasound2-dev gettext autopoint libtool gperf


echo "Building Freetype..."
git clone --depth 1 -b "$([ -n "${FREETYPE_VERSION}" ] && echo "VER-$(echo ${FREETYPE_VERSION} | tr '.' '-')" || echo "master")" https://github.com/lwjgl-ci/freetype freetype
cd ${CURRENT_DIR}/freetype

bash ./autogen.sh
bash ./configure \
    --host=${TARGET} \
    --prefix=${CURRENT_DIR}/freetype/build \
    --without-zlib \
    --with-brotli=system \
    --with-bzip2=no \
    --with-png=no \
    --with-harfbuzz=no \
    LD=${LD} \
    CC=${CC} \
    CXX=${CXX} \
    || error_code=$?

if [[ "${error_code}" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR ${error_code} , config.log:"
  cat ${CURRENT_DIR}/freetype/builds/unix/config.log
  exit ${error_code}
fi

PrintConfigurationInfo
CFLAGS="-O3 -fno-rtti -mllvm -polly" CXXFLAGS="-O3 -fno-rtti -mllvm -polly" make -j6
make install
find ${CURRENT_DIR}/freetype -name "libfreetype.so*" -exec cp -v {} ${DEPS_LIB_DIR}/ \;


echo "Cloning cups..."

cd ${CURRENT_DIR}
git clone --depth 1 -b "$([ -n "${CUPS_VERSION}" ] && echo "v${CUPS_VERSION}" || echo "master")" https://github.com/OpenPrinting/cups cups


echo "Building libiconv..."
git clone --depth 1 https://github.com/aaaapai/libiconv libiconv
cd ${CURRENT_DIR}/libiconv

bash ./autogen.sh
mkdir -p ./build_tools
cd ./build_tools
gcc -o genaliases ../lib/genaliases.c
gcc -DUSE_AIX_ALIASES -o genaliases_sysaix ../lib/genaliases.c
gcc -DUSE_HPUX_ALIASES -o genaliases_syshpux ../lib/genaliases.c
gcc -DUSE_OSF1_ALIASES -o genaliases_sysosf1 ../lib/genaliases.c
gcc -DUSE_SOLARIS_ALIASES -o genaliases_syssolaris ../lib/genaliases.c
gcc -DUSE_AIX -o genaliases_aix ../lib/genaliases2.c
gcc -DUSE_AIX -DUSE_AIX_ALIASES -o genaliases_aix_sysaix ../lib/genaliases2.c
gcc -DUSE_OSF1 -o genaliases_osf1 ../lib/genaliases2.c
gcc -DUSE_OSF1 -DUSE_OSF1_ALIASES -o genaliases_osf1_sysosf1 ../lib/genaliases2.c
gcc -DUSE_DOS -o genaliases_dos ../lib/genaliases2.c
gcc -DUSE_ZOS -o genaliases_zos ../lib/genaliases2.c
gcc -DUSE_EXTRA -o genaliases_extra ../lib/genaliases2.c
gcc -o genflags ../lib/genflags.c
gcc -o gentranslit ../lib/gentranslit.c
cd ${CURRENT_DIR}/libiconv

iconv_cmake_build () {
  mkdir -p  ${CURRENT_DIR}/libiconv/${TARGET}/build
  cd ${CURRENT_DIR}/libiconv

  export CMAKE_C_COMPILER_LAUNCHER=ccache
  export CMAKE_CXX_COMPILER_LAUNCHER=ccache

  PrintConfigurationInfo
  
  cmake ${CURRENT_DIR}/libiconv \
    -DANDROID_PLATFORM=${ANDROID_API} \
    -DANDROID_TOOLCHAIN_NAME=${TARGET} \
    -DANDROID_TOOLCHAIN=clang \
    -DCMAKE_ANDROID_STL_TYPE=c++_static \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_MAKE_PROGRAM=${NDK_PATH}/prebuilt/linux-x86_64/bin/make \
    -DCMAKE_TOOLCHAIN_FILE=${NDK_PATH}/build/cmake/android.toolchain.cmake \
    -DThreads_FOUND=ON \
    -DCMAKE_THREAD_LIBS_INIT="-pthread" \
    -DCMAKE_USE_PTHREADS_INIT=ON \
    -DCMAKE_INSTALL_PREFIX=${CURRENT_DIR}/libiconv/${TARGET}/install \
    -DCMAKE_VERBOSE_MAKEFILE=ON
    ${CFLAGS:+-DCMAKE_C_FLAGS="$CFLAGS"} \
    ${CPPFLAGS:+-DCMAKE_CXX_FLAGS="$CPPFLAGS"} \
    ${LDFLAGS:+-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS"}

  cmake --build  . --config Release --parallel 6
  cmake --install . --config Release
}

cd ${CURRENT_DIR}/libiconv
iconv_cmake_build

find ${CURRENT_DIR}/libiconv/${TARGET}/install -name "libiconv.a" -exec cp {} ${DEPS_LIB_DIR} \;
find ${CURRENT_DIR}/libiconv/${TARGET}/install -name "libcharset.a" -exec cp {} ${DEPS_LIB_DIR} \;

cp -r ${CURRENT_DIR}/libiconv/${TARGET}/install/include ${DEPS_INCLUDE_DIR}
