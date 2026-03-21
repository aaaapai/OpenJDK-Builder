#!/bin/bash
source ./scripts/utils.bash


cp -R /usr/include/X11 ${DEPS_INCLUDE_DIR}
cp -R /usr/include/fontconfig ${DEPS_INCLUDE_DIR}
cp ${CURRENT_DIR}/devkit_info/devkit.info.${TARGET_ARCH} ${NDK_TOOLCHAIN}

if [[ "${TARGET_ARCH}" == "arm32" ]]; then
  Set_C_CPPFLAGS -D__thumb__
else
  if [[ "${TARGET_ARCH}" == "x86" ]]; then
     Set_C_CPPFLAGS -mstackrealign
  fi
fi

Set_C_CPPFLAGS -DLE_STANDALONE

cd_to_script_dir
bash ./clone_jdk.bash
bash ./apply_jdk_patches.bash
cd ${CURRENT_DIR}/openjdk


bash ./configure \
      --with-version-pre="-ea" \
      --with-vendor-name="OpenJDK" \
      --with-version-opt="${GITHUB_ACTOR}-${GITHUB_SHA}" \
      --with-conf-name="${TARGET}" \
	  --openjdk-target="${TARGET}" \
	  --with-ccache-dir=/home/runner/.ccache \
      --with-boot-jdk-jvmargs="-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+UseNUMA" \
      --with-jvm-variants="server,zero" \
      --with-zlib=system \
      --with-jmod-compress=zip-1 \
      --with-external-symbols-in-bundles=none \
      --with-native-debug-symbols-level=1 \
      --disable-precompiled-headers \
      --enable-option-checking=fatal \
      --enable-linktime-gc \
      --disable-warnings-as-errors \
      --enable-ccache \
      --with-debug-level=${JDK_DEBUG_LEVEL} \
      --with-fontconfig-include="${DEPS_INCLUDE_DIR}" \
      --with-devkit="${NDK_TOOLCHAIN}" \
	  --with-toolchain-path="${NDK_TOOLCHAIN}/bin" \
      --with-debug-level=${JDK_DEBUG_LEVEL} \
      --with-cups-include="${CUPS_DIR}" \
      --with-extra-cflags="${CFLAGS}" \
      --with-extra-cxxflags="${CFLAGS}" \
      --with-extra-ldflags="${LDFLAGS}" \
      --with-freetype-include="${FREETYPE_DIR}/include/freetype2" \
      --with-freetype-lib="${FREETYPE_DIR}/lib" \
      --x-libraries="${DEPS_LIB_DIR}" \
      --with-toolchain-type=clang \
      --x-includes="${DEPS_INCLUDE_DIR}/X11" \
      OBJDUMP="${OBJDUMP}" \
      STRIP="${STRIP}" \
      NM="${NM}" \
      AR="${AR}" \
      OBJCOPY="${OBJCOPY}" \
      CC="${CC}" \
      CXX="${CXX}" \
      LD="${LD}" \
      CXXFILT="llvm-cxxfilt" \
      BUILD_CC="/usr/bin/clang" \
	  BUILD_CXX="/usr/bin/clang++" \
      BUILD_NM="${NM}" \
	  BUILD_AR="${AR}" \
	  BUILD_OBJCOPY="${OBJCOPY}" \
	  BUILD_STRIP="${STRIP}" \
	  --with-jobs=6

mkdir -R ./${TARGET}/openjdk-build
cd ./${TARGET}/openjdk-build
make -j6 images JOBS=6 || \
error_code=$?

if [[ "${error_code}" -ne 0 ]]; then
  echo "Build failure, exited with code ${error_code}."
  exit 1
fi
