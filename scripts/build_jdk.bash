#!/bin/bash
set -e
source ./scripts/utils.bash


cp -R /usr/include/X11 ${DEPS_INCLUDE_DIR}
cp -R /usr/include/fontconfig ${DEPS_INCLUDE_DIR}
cp ${CURRENT_DIR}/devkit_info/devkit.info.${TARGET_ARCH} ${NDK_TOOLCHAIN}

Set_C_CPPFLAGS -DLE_STANDALONE

chmod +x ${CURRENT_DIR}/wrapper/clang/buildcc-wrapped-clang
chmod +x ${CURRENT_DIR}/wrapper/clang/buildcxx-wrapped-clang++

cd_to_script_dir
bash ./clone_jdk.bash
bash ./apply_jdk_patches.bash
cd ${CURRENT_DIR}/openjdk

echo ""
PrintConfigurationInfo
echo ""

if [[ "${TARGET_JAVA_VERSION}" = "latest" ]] || [[ "${TARGET_JAVA_VERSION}" = "${LATEST_JAVA_VERSION}" ]] || [[ "${TARGET_JAVA_VERSION}" = "main" ]] || [[ "${TARGET_JAVA_VERSION}" = "dev" ]]; then
   export VERSION_PRE="ea"
   DEBUG_SYMBOLS_LEVEL="1"
elif [[ "${TARGET_JAVA_VERSION}" -ge 27 ]]; then
   export VERSION_PRE="beta"
   DEBUG_SYMBOLS_LEVEL="1"
else
   export VERSION_PRE="Android"
   DEBUG_SYMBOLS_LEVEL=""
fi


bash ./configure \
      --with-version-pre="${VERSION_PRE}" \
      --with-vendor-name="OpenJDK" \
      --with-version-opt="${GITHUB_ACTOR}-${GITHUB_SHA}" \
	  --with-vendor-bug-url="https://github.com/aaaapai/OpenJDK-Builder/issues/" \
	  --with-vendor-vm-bug-url="https://github.com/aaaapai/OpenJDK-Builder/issues/" \
	  --with-vendor-version-string="OpenJDK-built-with-aaaapai-OpenJDK-Builder" \
	  --with-vendor-url="https://github.com/openjdk/" \
      --with-conf-name="${TARGET}" \
	  --build="x86_64-pc-linux-gnu" \
	  --host="${TARGET}" \
	  --target="${TARGET}" \
      --with-boot-jdk-jvmargs="-Xms3G -Xmx3G -XX:+UseThreadPriorities -XX:MetaspaceSize=256M -XX:+UseG1GC -XX:+DisableExplicitGC -XX:+TieredCompilation" \
      --with-jvm-variants="server" \
	  --with-jvm-features="" \
      --with-external-symbols-in-bundles=none \
      ${{DEBUG_SYMBOLS_LEVEL}} \
      --disable-precompiled-headers \
      --enable-option-checking=fatal \
      --enable-linktime-gc \
      --disable-warnings-as-errors \
	  --enable-headless-only=yes \
      --with-debug-level=${JDK_DEBUG_LEVEL} \
	  ${DEBUG_SYMBOLS_LEVEL:+--with-native-debug-symbols-level=${DEBUG_SYMBOLS_LEVEL}} \
      --with-fontconfig-include="${DEPS_INCLUDE_DIR}" \
      --with-devkit="${NDK_TOOLCHAIN}" \
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
	  RANLIB="${RANLIB}" \
	  BUILD_OBJDUMP="${OBJDUMP}" \
	  BUILD_OBJCOPY="${OBJCOPY}" \
      BUILD_NM="${NM}" \
      BUILD_AR="${AR}" \
	  BUILD_CC="${CURRENT_DIR}/wrapper/clang/buildcc-wrapped-clang" \
	  BUILD_CXX="${CURRENT_DIR}/wrapper/clang/buildcxx-wrapped-clang++" \
      CXXFILT="llvm-cxxfilt" \
	  --disable-full-docs \
	  --enable-javac-server \
	  --with-memory-size=3072 \
	  --with-jobs=6 || \
error_code=$?

if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

cd ./build/${TARGET}
make JOBS=6 images || \
error_code=$?

if [[ "${error_code}" -ne 0 ]]; then
  echo "Build failure, exited with code ${error_code}."
  make JOBS=6 images
fi


cd ${CURRENT_DIR}
cd_to_script_dir
bash ./remove_debuginfo.bash
bash ./pack_java.bash
