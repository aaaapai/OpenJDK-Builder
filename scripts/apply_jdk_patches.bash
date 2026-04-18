#!/bin/bash
set -e


echo "Cloning JDK..."

PATCHES_BASE_DIR="${CURRENT_DIR}/patches"
PATCHES_DIR="${PATCHES_BASE_DIR}/${TARGET_JAVA_VERSION}"

echo "JAVA_VERSION=${TARGET_JAVA_VERSION}"

if [ ! -d "${PATCHES_DIR}" ]; then
    echo "Warning: Patches don't exist ( ${PATCHES_DIR} )"
    echo "Skip patching"
    exit 0
fi

cd "${CURRENT_DIR}/openjdk"

PATCH_COUNT=$(find "${PATCHES_DIR}" -maxdepth 1 -name "*.diff" -o -name "*.patch" | wc -l)
if [ ${PATCH_COUNT} -eq 0 ]; then
    echo "Warning: Not found .diff or .patch files in ${PATCHES_DIR}"
    echo "skip patching"
    exit 0
fi

APPLIED_PATCHES=()
FAILED_PATCHES=()

find "${PATCHES_DIR}" -maxdepth 1 \( -name "*.diff" -o -name "*.patch" \) -print0 | while IFS= read -r -d '' patch_file; do
    patch_name=$(basename "${patch_file}")
    git apply --reject --whitespace=fix --verbose "${patch_file}"
done

wait

echo ""
echo "Patched JDK ${TARGET_JAVA_VERSION} successfully."
