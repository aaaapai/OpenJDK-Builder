#!/bin/bash

# 检查必要参数
if [ -z "${TARGET_JAVA_VERSION}" ]; then
    echo "错误: TARGET_JAVA_VERSION 环境变量未设置"
    exit 1
fi

cd ${CURRENT_DIR}

# 定义支持的LTS版本
SUPPORTED_LTS_VERSIONS=("8" "11" "17" "21" "25")

echo "配置: JAVA_VERSION=${TARGET_JAVA_VERSION}, JAVA_TAG=${TARGET_JAVA_TAG:-}, JAVA_BRANCH=${TARGET_JAVA_BRANCH:-}"

# 清理已存在的目录(这里应该检测是否存在再清理)
if [ -d "openjdk" ]; then
    echo "删除已存在的 openjdk 目录"
    rm -rf openjdk
fi

# 处理特殊版本
if [[ "${TARGET_JAVA_VERSION}" = "latest" ]] || [[ "${TARGET_JAVA_VERSION}" = "27" ]] || [[ "${TARGET_JAVA_VERSION}" = "main" ]] || [[ "${TARGET_JAVA_VERSION}" = "dev" ]]; then
    echo "使用最新开发版本 (main分支)"
    git clone --depth 1 -b master https://github.com/openjdk/mobile openjdk
fi

# 检查是否是dev分支
if [[ "${TARGET_JAVA_BRANCH:-}" = "dev" ]]; then
    # 验证版本是否支持dev分支
    is_supported=0
    for version in "${SUPPORTED_LTS_VERSIONS[@]}"; do
        if [ "${TARGET_JAVA_VERSION}" = "${version}" ]; then
            is_supported=1
            break
        fi
    done
    
    if [[ ${is_supported} -eq 1 ]]; then
        echo "使用开发分支: jdk${TARGET_JAVA_VERSION}u-dev"
        git clone --depth 1 -b dev https://github.com/openjdk/jdk${TARGET_JAVA_VERSION}u-dev openjdk
    else
        echo "警告: 版本 ${TARGET_JAVA_VERSION} 不支持dev分支，回退到标准分支"
    fi
fi

# 检查是否有显式指定的tag
if [[ -n "${TARGET_JAVA_TAG:-}" ]]; then
    TAG_NAME="${TARGET_JAVA_VERSION}-${TARGET_JAVA_TAG}"
    echo "使用指定tag: ${TAG_NAME}"
    git clone --depth 1 -b ${TAG_NAME} https://github.com/openjdk/jdk${TARGET_JAVA_VERSION}u openjdk
fi

# 检查版本号是否包含点号（表示小版本）
if [[ "${TARGET_JAVA_VERSION}" == *.* ]]; then
    # 包含小版本，使用-ga tag
    TAG_NAME="${TARGET_JAVA_VERSION}-ga"
    echo "使用小版本tag: ${TAG_NAME}"
    git clone --depth 1 -b ${TAG_NAME} https://github.com/openjdk/jdk${TARGET_JAVA_VERSION%%.*}u openjdk
else
    # 大版本，默认使用master分支
    echo "使用大版本master分支"
    git clone --depth 1 -b master https://github.com/openjdk/mobile openjdk
fi

echo "成功: OpenJDK ${TARGET_JAVA_VERSION} 已克隆到 openjdk 目录"
