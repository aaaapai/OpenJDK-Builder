#!/bin/bash
set -e  # 遇到错误立即退出


PATCHES_BASE_DIR="${CURRENT_DIR}/patches"
PATCHES_DIR="${PATCHES_BASE_DIR}/${TARGET_JAVA_VERSION}"

echo "配置: JAVA_VERSION=${TARGET_JAVA_VERSION}"

# 检查补丁目录是否存在
if [ ! -d "${PATCHES_DIR}" ]; then
    echo "警告: 补丁目录不存在: ${PATCHES_DIR}"
    echo "跳过补丁应用步骤"
    exit 0
fi

# 进入 openjdk 目录
cd "${CURRENT_DIR}/openjdk"

# 检查是否有补丁文件
PATCH_COUNT=$(find "${PATCHES_DIR}" -maxdepth 1 -name "*.diff" -o -name "*.patch" | wc -l)
if [ ${PATCH_COUNT} -eq 0 ]; then
    echo "警告: ${PATCHES_DIR} 目录中没有找到 .diff 或 .patch 文件"
    echo "跳过补丁应用步骤"
    exit 0
fi

echo "找到 ${PATCH_COUNT} 个补丁文件，开始应用..."

# 记录应用的补丁
APPLIED_PATCHES=()
FAILED_PATCHES=()

# 查找并应用所有补丁文件
find "${PATCHES_DIR}" -maxdepth 1 \( -name "*.diff" -o -name "*.patch" \) -print0 | while IFS= read -r -d '' patch_file; do
    patch_name=$(basename "${patch_file}")
    echo ""
    echo "========================================="
    echo "正在应用补丁: ${patch_name}"
    echo "========================================="
    
    # 尝试应用补丁，使用更宽松的选项
    if git apply --reject --whitespace=fix --verbose "${patch_file}" 2>&1; then
        echo "✓ 补丁应用成功: ${patch_name}"
        APPLIED_PATCHES+=("${patch_name}")
    else
        echo "✗ git apply 失败..." 
    fi
done

# 等待所有后台进程完成
wait

echo ""
echo "========================================="
echo "补丁应用完成"
echo "========================================="
echo "成功应用: ${#APPLIED_PATCHES[@]} 个补丁"
if [ ${#APPLIED_PATCHES[@]} -gt 0 ]; then
    printf '%s\n' "${APPLIED_PATCHES[@]}"
fi

if [ ${#FAILED_PATCHES[@]} -gt 0 ]; then
    echo "失败: ${#FAILED_PATCHES[@]} 个补丁"
    printf '%s\n' "${FAILED_PATCHES[@]}"
    echo ""
    echo "警告: 部分补丁应用失败"
    # 在 CI 环境中，如果需要严格检查，可以取消下面这行的注释
    # exit 1
fi

# 显示应用补丁后的更改摘要
echo ""
echo "补丁应用后的更改摘要:"
git diff --stat --exit-code || true

echo ""
echo "成功: JDK ${TARGET_JAVA_VERSION} 补丁处理完成"

cd ..
