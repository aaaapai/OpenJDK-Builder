#!/bin/bash

echo"Packing java..."


cd ${CURRENT_DIR}/openjdk/build/${TARGET}/jre
tar cJf ../jre27-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/jdk
tar cJf ../jdk27-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .

cd ${CURRENT_DIR}/openjdk/build/${TARGET}/dizout
tar cJf ../jdk27debuginfo-${TARGET_OS}-${TARGET_ARCH}-${GITHUB_SHA}.tar.xz .
