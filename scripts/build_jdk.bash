#!/bin/bash
bash ./scripts/utils.bash


cp -R /usr/include/X11 ${DEPS_INCLUDE_DIR}

if [[ "$TARGET_ARCH" == "arm32" ]]; then
  Set_CFLAGS -D__thumb__
  Set_CPPFLAGS -D__thumb__
else
  if [[ "$TARGET_ARCH" == "x86" ]]; then
     Set_CFLAGS -mstackrealign
     Set_CPPFLAGS -mstackrealign
  fi
fi

Set_CFLAGS -DLE_STANDALONE

cd_to_script_dir
bash ./clone_jdk.bash
cd ${CURRENT_DIR}/openjdk










bash ./configure \
      --with-version-pre="-ea" \
      --with-vendor-name="OpenJDK" \
      --with-extra-build-info="built with aaaapai/OpenJDK-Builder" \
      --with-version-opt="${GITHUB_ACTOR}-${GITHUB_SHA}" \
      --with-conf-name="${TARGET}" \
      --with-boot-jdk-jvmargs="-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+UseNUMA" \
      --with-jvm-variants=server,zero \
      --with-zlib=system \
      --with-jmod-compress=zip-1 \
      --with-external-symbols-in-bundles=none \
      --with-native-debug-symbols-level=none \
      --disable-precompiled-headers \
      --enable-option-checking=fatal \
      --enable-linktime-gc \
      --disable-warnings-as-errors \
      --enable-ccache \
      --with-debug-level=${JDK_DEBUG_LEVEL} \
      --with-fontconfig-include="${DEPS_INCLUDE_DIR}" \
      --with-devkit="${TOOLCHAIN}" \
      --with-debug-level=${JDK_DEBUG_LEVEL} \
      --with-cups-include="${CUPS_DIR}" \
      --with-extra-cflags="${CFLAGS}" \
      --with-extra-cxxflags="${CFLAGS}" \
      --with-extra-ldflags="${LDFLAGS}" \
      --with-freetype-include="${FREETYPE_DIR}/include/freetype2" \
      --with-freetype-lib="${FREETYPE_DIR}/lib" \
      --x-libraries="${DEPS_LIB_DIR}" \ # TODO
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
      BUILD_NM="/usr/bin/llvm-nm" \
	  BUILD_AR="/usr/bin/llvm-ar" \
	  BUILD_OBJCOPY="/usr/bin/llvm-objcopy" \
	  BUILD_STRIP="/usr/bin/llvm-strip" \
	  --with-jobs=6

cd ./build
make -j6 images JOBS=6 || \
error_code=$?

if [[ "${error_code}" -ne 0 ]]; then
  echo "Build failure, exited with code ${error_code}."
  exit 1
fi
