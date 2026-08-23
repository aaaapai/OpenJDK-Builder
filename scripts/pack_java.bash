#!/bin/bash
set -e

echo "Packing java..."


cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/jre
tar cJf ../jre${TARGET_JAVA_VERSION}-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/jdk
tar cJf ../jdk${TARGET_JAVA_VERSION}-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/symbols
tar cJf ../symbols${TARGET_JAVA_VERSION}-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .
