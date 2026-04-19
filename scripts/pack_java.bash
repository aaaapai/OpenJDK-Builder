#!/bin/bash
set -e

echo "Packing java..."


cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/jre
tar cJf ../jre27-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/jdk
tar cJf ../jdk27-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/images/symbols
tar cJf ../symbols27-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .
