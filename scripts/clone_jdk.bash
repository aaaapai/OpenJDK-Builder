#!/bin/bash
set -e

if [ -z "${TARGET_JAVA_VERSION}" ]; then
    echo "error: TARGET_JAVA_VERSION env have not set"
    exit 1
fi

cd ${CURRENT_DIR}

SUPPORTED_LTS_VERSIONS=("8" "11" "17" "21" "25")

echo "JAVA_VERSION=${TARGET_JAVA_VERSION}, JAVA_TAG=${TARGET_JAVA_TAG:-}, JAVA_BRANCH=${TARGET_JAVA_BRANCH:-}"

if [ -d "openjdk" ]; then
    echo "Deleting openjdk have been existed..."
    rm -rf openjdk
fi

if [[ "${TARGET_JAVA_VERSION}" = "latest" ]] || [[ "${TARGET_JAVA_VERSION}" = "27" ]] || [[ "${TARGET_JAVA_VERSION}" = "main" ]] || [[ "${TARGET_JAVA_VERSION}" = "dev" ]]; then
    echo "Use the latest version of JDK."
    git clone --depth 1 -b master https://github.com/openjdk/jdk openjdk
    exit 0
fi

if [[ "${TARGET_JAVA_BRANCH:-}" = "dev" ]]; then
    is_supported=0
    for version in "${SUPPORTED_LTS_VERSIONS[@]}"; do
        if [ "${TARGET_JAVA_VERSION}" = "${version}" ]; then
            is_supported=1
            break
        fi
    done
    
    if [[ ${is_supported} -eq 1 ]]; then
        git clone --depth 1 -b dev https://github.com/openjdk/jdk${TARGET_JAVA_VERSION}u-dev openjdk
        exit 0
    else
        echo "Warning: version ${TARGET_JAVA_VERSION} has no a dev branch, falling back to standard branch."
    fi
fi

if [[ -n "${TARGET_JAVA_TAG:-}" ]]; then
    TAG_NAME="${TARGET_JAVA_VERSION}-${TARGET_JAVA_TAG}"
    echo "tag: ${TAG_NAME}"
    git clone --depth 1 -b ${TAG_NAME} https://github.com/openjdk/jdk${TARGET_JAVA_VERSION}u openjdk
    exit 0
fi

if [[ "${TARGET_JAVA_VERSION}" == *.* ]]; then
    TAG_NAME="${TARGET_JAVA_VERSION}-ga"
    echo "tag: ${TAG_NAME}"
    git clone --depth 1 -b ${TAG_NAME} https://github.com/openjdk/jdk${TARGET_JAVA_VERSION%%.*}u openjdk
else
    git clone --depth 1 -b master https://github.com/openjdk/jdk${TARGET_JAVA_VERSION}u openjdk
fi
